


SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


CREATE SCHEMA IF NOT EXISTS "public";


ALTER SCHEMA "public" OWNER TO "pg_database_owner";


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE TYPE "public"."accountability_status" AS ENUM (
    'paid',
    'overdue',
    'unpaid',
    'partial'
);


ALTER TYPE "public"."accountability_status" OWNER TO "postgres";


CREATE TYPE "public"."announcement_category" AS ENUM (
    'urgent',
    'reminder',
    'info'
);


ALTER TYPE "public"."announcement_category" OWNER TO "postgres";


CREATE TYPE "public"."condo_role" AS ENUM (
    'manager',
    'resident',
    'unassigned'
);


ALTER TYPE "public"."condo_role" OWNER TO "postgres";


CREATE TYPE "public"."resident_status" AS ENUM (
    'active',
    'vacated',
    'pending',
    'notice_given',
    'evicted'
);


ALTER TYPE "public"."resident_status" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."claim_resident_profile"("p_condo_code" "text", "p_resident_code" "text", "p_auth_id" "uuid" DEFAULT "auth"."uid"()) RETURNS "uuid"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_placeholder_profile_id uuid;
  v_placeholder_role public.condo_role;
  v_resident_profile_id uuid;
begin
  if p_auth_id is null then
    raise exception 'No authenticated user found.';
  end if;

  select p.id, p.role
    into v_placeholder_profile_id, v_placeholder_role
  from public.profiles p
  where p.auth_id = p_auth_id
  limit 1;

  if v_placeholder_profile_id is not null
     and coalesce(v_placeholder_role, 'unassigned'::public.condo_role)
         <> 'unassigned'::public.condo_role
  then
    raise exception 'This signed-in user is already linked to a profile.';
  end if;

  select r.id
    into v_resident_profile_id
  from public.residents r
  join public.units u on u.id = r.unit_id
  join public.condos c on c.id = u.condo_id
  join public.profiles p on p.id = r.id
  where upper(c.code) = upper(trim(p_condo_code))
    and upper(r.code) = upper(trim(p_resident_code))
    and r.status = 'active'
    and p.role = 'resident'::public.condo_role
  limit 1;

  if v_resident_profile_id is null then
    raise exception 'Invalid BH code or resident code.';
  end if;

  if exists (
    select 1
    from public.profiles p
    where p.id = v_resident_profile_id
      and p.auth_id is not null
      and p.auth_id <> p_auth_id
  ) then
    raise exception 'This resident profile is already linked to an account.';
  end if;

  if v_placeholder_profile_id is not null
     and v_placeholder_profile_id <> v_resident_profile_id
  then
    update public.profiles
    set auth_id = null
    where id = v_placeholder_profile_id;

    delete from public.profiles
    where id = v_placeholder_profile_id;
  end if;

  update public.profiles
  set auth_id = p_auth_id,
      role = 'resident'::public.condo_role
  where id = v_resident_profile_id;

  return v_resident_profile_id;
end;
$$;


ALTER FUNCTION "public"."claim_resident_profile"("p_condo_code" "text", "p_resident_code" "text", "p_auth_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_condo_id bigint;
  v_id bigint;
begin
  if not public.profile_is_manager() then
    raise exception 'Only managers can create announcements.';
  end if;

  v_profile_id := public.current_profile_id();
  v_condo_id := public.current_manager_condo_id();

  if v_profile_id is null or v_condo_id is null then
    raise exception 'Missing manager context.';
  end if;

  insert into public.announcements (condo_id, posted_by, title, content, category)
  values (v_condo_id, v_profile_id, trim(p_title), trim(p_content), p_category)
  returning id into v_id;

  return v_id;
end;
$$;


ALTER FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) RETURNS TABLE("resident_id" "uuid", "resident_code" "text")
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_code text;
  v_now timestamptz := now();
begin
  if not public.profile_is_manager() then
    raise exception 'Only managers can create resident profiles.';
  end if;

  -- Ensure the unit belongs to the manager's condo.
  if not exists (
    select 1
    from public.units u
    where u.id = p_unit_id
      and u.condo_id = public.current_manager_condo_id()
  ) then
    raise exception 'Invalid unit for current manager.';
  end if;

  -- Generate an 8-character resident code. Retry on collisions (within condo).
  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (
      select 1
      from public.residents r
      join public.units u on u.id = r.unit_id
      where r.code = v_code
        and u.condo_id = public.current_manager_condo_id()
    );
  end loop;

  insert into public.profiles (first_name, last_name, role, auth_id)
  values (trim(p_first_name), trim(p_last_name), 'resident'::public.condo_role, null)
  returning id into v_profile_id;

  insert into public.residents (
    id,
    unit_id,
    status,
    requested_at,
    approved_at,
    left_at,
    code,
    profile_id
  )
  values (
    v_profile_id,
    p_unit_id,
    'active'::public.resident_status,
    v_now,
    v_now,
    null,
    v_code,
    null
  );

  resident_id := v_profile_id;
  resident_code := v_code;
  return next;
end;
$$;


ALTER FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_manager_can_access_bill_receiver"("p_received_by" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select public.manager_can_access_resident(p_received_by)
$$;


ALTER FUNCTION "public"."current_manager_can_access_bill_receiver"("p_received_by" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_manager_can_access_resident"("p_resident_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select public.manager_can_access_resident(p_resident_id)
$$;


ALTER FUNCTION "public"."current_manager_can_access_resident"("p_resident_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_manager_can_review_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select (
    public.manager_can_access_resident(p_paid_by)
    and (
      exists (
        select 1
        from public.monthly_bills mb
        where mb.id = p_monthly_bill_id
          and mb.received_by = p_paid_by
      )
      or exists (
        select 1
        from public.one_time_fees otf
        where otf.id = p_one_time_fee_id
          and otf.received_by = p_paid_by
      )
    )
  )
$$;


ALTER FUNCTION "public"."current_manager_can_review_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_manager_condo_id"() RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select m.condo_id
  from public.managers m
  where m.id = public.current_profile_id()
  limit 1
$$;


ALTER FUNCTION "public"."current_manager_condo_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_profile_can_access_conversation"("p_manager_id" "uuid", "p_resident_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select (
    public.current_profile_id() in (p_manager_id, p_resident_id)
    and public.manager_resident_same_condo(p_manager_id, p_resident_id)
  )
$$;


ALTER FUNCTION "public"."current_profile_can_access_conversation"("p_manager_id" "uuid", "p_resident_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_profile_can_access_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select (
    public.current_profile_id() = p_paid_by
    or exists (
      select 1
      from public.monthly_bills mb
      where mb.id = p_monthly_bill_id
        and mb.received_by = p_paid_by
        and public.manager_can_access_resident(mb.received_by)
    )
    or exists (
      select 1
      from public.one_time_fees otf
      where otf.id = p_one_time_fee_id
        and otf.received_by = p_paid_by
        and public.manager_can_access_resident(otf.received_by)
    )
  )
$$;


ALTER FUNCTION "public"."current_profile_can_access_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_profile_id"() RETURNS "uuid"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select p.id
  from public.profiles p
  where p.auth_id = auth.uid()
  limit 1
$$;


ALTER FUNCTION "public"."current_profile_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_profile_role"() RETURNS "public"."condo_role"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select p.role
  from public.profiles p
  where p.auth_id = auth.uid()
  limit 1
$$;


ALTER FUNCTION "public"."current_profile_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_resident_can_submit_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select (
    public.current_profile_id() = p_paid_by
    and (
      exists (
        select 1
        from public.monthly_bills mb
        where mb.id = p_monthly_bill_id
          and mb.received_by = p_paid_by
      )
      or exists (
        select 1
        from public.one_time_fees otf
        where otf.id = p_one_time_fee_id
          and otf.received_by = p_paid_by
      )
    )
  )
$$;


ALTER FUNCTION "public"."current_resident_can_submit_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."current_resident_condo_id"() RETURNS bigint
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select u.condo_id
  from public.residents r
  join public.units u on u.id = r.unit_id
  where r.id = public.current_profile_id()
    and r.status = 'active'
  limit 1
$$;


ALTER FUNCTION "public"."current_resident_condo_id"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
BEGIN
  INSERT INTO public.profiles (auth_id, first_name, role)
  VALUES (new.id, null, 'unassigned'); -- Values matching your profiles_rows.sql format
  RETURN new;
END;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."manager_can_access_resident"("p_resident_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.residents r
    join public.units u on u.id = r.unit_id
    where r.id = p_resident_id
      and u.condo_id = public.current_manager_condo_id()
  )
$$;


ALTER FUNCTION "public"."manager_can_access_resident"("p_resident_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."manager_resident_same_condo"("p_manager_id" "uuid", "p_resident_id" "uuid") RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select exists (
    select 1
    from public.managers m
    join public.residents r on r.id = p_resident_id
    join public.units u on u.id = r.unit_id
    where m.id = p_manager_id
      and m.condo_id = u.condo_id
      and r.status = 'active'
  )
$$;


ALTER FUNCTION "public"."manager_resident_same_condo"("p_manager_id" "uuid", "p_resident_id" "uuid") OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profile_is_manager"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select public.current_profile_role() = 'manager'::public.condo_role
$$;


ALTER FUNCTION "public"."profile_is_manager"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."profile_is_resident"() RETURNS boolean
    LANGUAGE "sql" STABLE SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
  select public.current_profile_role() = 'resident'::public.condo_role
$$;


ALTER FUNCTION "public"."profile_is_resident"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text" DEFAULT ''::"text", "p_description" "text" DEFAULT ''::"text", "p_image_url" "text" DEFAULT ''::"text", "p_gallery_urls" "text"[] DEFAULT '{}'::"text"[]) RETURNS bigint
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_profile_id uuid;
  v_condo_id bigint;
  v_code text;
begin
  v_profile_id := public.current_profile_id();
  if v_profile_id is null then
    raise exception 'No profile linked to this signed-in user.';
  end if;

  -- Require manager role.
  if not public.profile_is_manager() then
    raise exception 'Only managers can create condos.';
  end if;

  -- Generate an 8-character code. Retry on collisions.
  loop
    v_code := upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
    exit when not exists (select 1 from public.condos c where c.code = v_code);
  end loop;

  insert into public.condos (name, location, description, image_url, gallery_urls, code)
  values (
    trim(p_name),
    coalesce(p_location, ''),
    coalesce(p_description, ''),
    coalesce(p_image_url, ''),
    coalesce(p_gallery_urls, '{}'::text[]),
    v_code
  )
  returning id into v_condo_id;

  insert into public.managers (id, condo_id)
  values (v_profile_id, v_condo_id)
  on conflict (id) do update set condo_id = excluded.condo_id;

  return v_condo_id;
end;
$$;


ALTER FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text", "p_description" "text", "p_image_url" "text", "p_gallery_urls" "text"[]) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."update_resident_profile"("p_resident_id" "uuid", "p_full_name" "text", "p_unit_id" integer) RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
declare
  v_manager_id uuid := public.current_profile_id();
  v_condo_id bigint;
  v_capacity integer;
  v_occupied integer;
  v_first_name text;
  v_last_name text;
begin
  select condo_id into v_condo_id
  from public.managers
  where id = v_manager_id;

  if v_condo_id is null then
    raise exception 'Only managers can update resident profiles.';
  end if;

  select capacity into v_capacity
  from public.units
  where id = p_unit_id
    and condo_id = v_condo_id
  for update;

  if not found then
    raise exception 'Selected unit does not belong to your condo.';
  end if;

  if not public.manager_can_access_resident(p_resident_id) then
    raise exception 'Resident does not belong to your condo.';
  end if;

  if v_capacity is not null then
    select count(*)
      into v_occupied
    from public.residents r
    where r.unit_id = p_unit_id
      and r.status = 'active'
      and r.id <> p_resident_id;

    if v_occupied >= v_capacity then
      raise exception 'This unit is already at maximum capacity (%).', v_capacity;
    end if;
  end if;

  v_first_name := split_part(trim(p_full_name), ' ', 1);
  v_last_name := nullif(trim(regexp_replace(trim(p_full_name), '^\S+\s*', '')), '');

  update public.profiles
  set first_name = v_first_name,
      last_name = coalesce(v_last_name, ''),
      role = 'resident'::public.condo_role
  where id = p_resident_id;

  update public.residents
  set unit_id = p_unit_id,
      status = 'active',
      left_at = null
  where id = p_resident_id;
end;
$$;


ALTER FUNCTION "public"."update_resident_profile"("p_resident_id" "uuid", "p_full_name" "text", "p_unit_id" integer) OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."vacate_resident"("p_resident_id" "uuid") RETURNS "void"
    LANGUAGE "plpgsql" SECURITY DEFINER
    SET "search_path" TO 'public'
    AS $$
begin
  if not public.manager_can_access_resident(p_resident_id) then
    raise exception 'Resident does not belong to your condo.';
  end if;

  update public.residents
  set status = 'vacated',
      left_at = now()
  where id = p_resident_id;
end;
$$;


ALTER FUNCTION "public"."vacate_resident"("p_resident_id" "uuid") OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."bills" (
    "id" bigint NOT NULL,
    "one_time_fee_id" bigint,
    "name" "text" NOT NULL,
    "amount" integer NOT NULL,
    "monthly_bill_id" bigint
);


ALTER TABLE "public"."bills" OWNER TO "postgres";


ALTER TABLE "public"."bills" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."Bills_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."announcements" (
    "id" bigint NOT NULL,
    "condo_id" bigint NOT NULL,
    "posted_by" "uuid",
    "title" "text" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "category" "public"."announcement_category"
);


ALTER TABLE "public"."announcements" OWNER TO "postgres";


ALTER TABLE "public"."announcements" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."announcements_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."condos" (
    "id" bigint NOT NULL,
    "name" "text" NOT NULL,
    "code" "text" NOT NULL,
    "capacity" integer,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "location" "text" DEFAULT ''::"text" NOT NULL,
    "description" "text" DEFAULT ''::"text" NOT NULL,
    "image_url" "text" DEFAULT ''::"text" NOT NULL,
    "gallery_urls" "text"[] DEFAULT '{}'::"text"[] NOT NULL,
    CONSTRAINT "condos_capacity_check" CHECK (("capacity" > 0)),
    CONSTRAINT "condos_code_check" CHECK (("char_length"("code") = 8))
);


ALTER TABLE "public"."condos" OWNER TO "postgres";


ALTER TABLE "public"."condos" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."condos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."conversations" (
    "id" bigint NOT NULL,
    "manager_id" "uuid" NOT NULL,
    "resident_id" "uuid" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "updated_at" timestamp with time zone DEFAULT "now"(),
    "manager_last_read_at" timestamp with time zone DEFAULT "now"(),
    "resident_last_read_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."conversations" OWNER TO "postgres";


ALTER TABLE "public"."conversations" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."conversations_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."managers" (
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "condo_id" bigint NOT NULL,
    "id" "uuid" NOT NULL
);


ALTER TABLE "public"."managers" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."messages" (
    "id" bigint NOT NULL,
    "conversation_id" bigint NOT NULL,
    "sender_id" "uuid" NOT NULL,
    "content" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."messages" OWNER TO "postgres";


ALTER TABLE "public"."messages" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."messages_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."monthly_bills" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "received_by" "uuid" NOT NULL,
    "posted_by" "uuid" NOT NULL,
    "due_date" "date" NOT NULL,
    "status" "public"."accountability_status" DEFAULT 'unpaid'::"public"."accountability_status" NOT NULL
);


ALTER TABLE "public"."monthly_bills" OWNER TO "postgres";


ALTER TABLE "public"."monthly_bills" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."monthly_bills_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."notifications" (
    "id" bigint NOT NULL,
    "profile_id" "uuid" NOT NULL,
    "type" "text" NOT NULL,
    "content" "text" NOT NULL,
    "is_read" boolean DEFAULT false,
    "created_at" timestamp with time zone DEFAULT "now"(),
    CONSTRAINT "notifications_type_check" CHECK (("type" = ANY (ARRAY['message'::"text", 'announcement'::"text", 'payment'::"text", 'approval'::"text"])))
);


ALTER TABLE "public"."notifications" OWNER TO "postgres";


ALTER TABLE "public"."notifications" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."notifications_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."one_time_fees" (
    "id" bigint NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "received_by" "uuid" NOT NULL,
    "posted_by" "uuid" NOT NULL,
    "due_date" "date" NOT NULL,
    "status" "public"."accountability_status" DEFAULT 'unpaid'::"public"."accountability_status" NOT NULL
);


ALTER TABLE "public"."one_time_fees" OWNER TO "postgres";


ALTER TABLE "public"."one_time_fees" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."one_time_fees_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."payment_proofs" (
    "id" bigint NOT NULL,
    "payment_id" bigint NOT NULL,
    "uploaded_by" "uuid" NOT NULL,
    "file_path" "text" NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."payment_proofs" OWNER TO "postgres";


ALTER TABLE "public"."payment_proofs" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."payment_proofs_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."payments" (
    "id" bigint NOT NULL,
    "monthly_bill_id" bigint,
    "paid_by" "uuid" NOT NULL,
    "validated_by" "uuid",
    "amount" numeric NOT NULL,
    "created_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" NOT NULL,
    "one_time_fee_id" bigint,
    "proof_url" "text",
    "remark" "text",
    "rejection_reason" "text",
    CONSTRAINT "payments_amount_positive" CHECK (("amount" > (0)::numeric)),
    CONSTRAINT "payments_has_one_bill_target" CHECK ((((("monthly_bill_id" IS NOT NULL))::integer + (("one_time_fee_id" IS NOT NULL))::integer) = 1)),
    CONSTRAINT "payments_status_check" CHECK (("status" = ANY (ARRAY['pending'::"text", 'completed'::"text", 'rejected'::"text"])))
);


ALTER TABLE "public"."payments" OWNER TO "postgres";


ALTER TABLE "public"."payments" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."payments_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "first_name" "text" DEFAULT 'User'::"text",
    "created_at" timestamp with time zone DEFAULT "now"(),
    "last_name" "text",
    "role" "public"."condo_role" DEFAULT 'unassigned'::"public"."condo_role" NOT NULL,
    "auth_id" "uuid"
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."residents" (
    "unit_id" bigint NOT NULL,
    "requested_at" timestamp with time zone DEFAULT "now"() NOT NULL,
    "approved_at" timestamp with time zone,
    "left_at" timestamp with time zone,
    "status" "public"."resident_status" DEFAULT 'pending'::"public"."resident_status",
    "id" "uuid" NOT NULL,
    "code" "text",
    "profile_id" "uuid",
    CONSTRAINT "residents_code_not_empty" CHECK ((("code" IS NULL) OR ("length"(TRIM(BOTH FROM "code")) = 8)))
);


ALTER TABLE "public"."residents" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."units" (
    "id" integer NOT NULL,
    "name" "text" NOT NULL,
    "capacity" integer NOT NULL,
    "condo_id" bigint NOT NULL,
    CONSTRAINT "units_capacity_check" CHECK (("capacity" > 0)),
    CONSTRAINT "units_capacity_positive" CHECK ((("capacity" IS NULL) OR ("capacity" > 0)))
);


ALTER TABLE "public"."units" OWNER TO "postgres";


ALTER TABLE "public"."units" ALTER COLUMN "id" ADD GENERATED BY DEFAULT AS IDENTITY (
    SEQUENCE NAME "public"."units_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1
);



ALTER TABLE ONLY "public"."bills"
    ADD CONSTRAINT "Bills_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."condos"
    ADD CONSTRAINT "condos_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."condos"
    ADD CONSTRAINT "condos_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_manager_id_resident_id_key" UNIQUE ("manager_id", "resident_id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."managers"
    ADD CONSTRAINT "managers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."monthly_bills"
    ADD CONSTRAINT "monthly_bills_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."one_time_fees"
    ADD CONSTRAINT "one_time_fees_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payment_proofs"
    ADD CONSTRAINT "payment_proofs_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_auth_id_key" UNIQUE ("auth_id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."residents"
    ADD CONSTRAINT "residents_code_key" UNIQUE ("code");



ALTER TABLE ONLY "public"."residents"
    ADD CONSTRAINT "residents_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "unique_conversation_pair" UNIQUE ("manager_id", "resident_id");



ALTER TABLE ONLY "public"."units"
    ADD CONSTRAINT "units_pkey" PRIMARY KEY ("id");



CREATE INDEX "idx_conversations_manager_resident" ON "public"."conversations" USING "btree" ("manager_id", "resident_id");



CREATE INDEX "idx_conversations_updated_at" ON "public"."conversations" USING "btree" ("updated_at" DESC);



CREATE INDEX "managers_condo_id_idx" ON "public"."managers" USING "btree" ("condo_id");



CREATE INDEX "payments_paid_by_status_idx" ON "public"."payments" USING "btree" ("paid_by", "status");



CREATE INDEX "payments_status_created_at_idx" ON "public"."payments" USING "btree" ("status", "created_at" DESC);



CREATE INDEX "residents_code_idx" ON "public"."residents" USING "btree" ("code");



CREATE INDEX "residents_unit_id_status_idx" ON "public"."residents" USING "btree" ("unit_id", "status");



CREATE INDEX "units_condo_id_idx" ON "public"."units" USING "btree" ("condo_id");



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_condo_id_fkey" FOREIGN KEY ("condo_id") REFERENCES "public"."condos"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."announcements"
    ADD CONSTRAINT "announcements_posted_by_fkey" FOREIGN KEY ("posted_by") REFERENCES "public"."profiles"("id") ON DELETE SET NULL;



ALTER TABLE ONLY "public"."bills"
    ADD CONSTRAINT "bills_monthly_bill_id_fkey" FOREIGN KEY ("monthly_bill_id") REFERENCES "public"."monthly_bills"("id");



ALTER TABLE ONLY "public"."bills"
    ADD CONSTRAINT "bills_one_time_fee_id_fkey" FOREIGN KEY ("one_time_fee_id") REFERENCES "public"."one_time_fees"("id");



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_manager_id_fkey" FOREIGN KEY ("manager_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."conversations"
    ADD CONSTRAINT "conversations_resident_id_fkey" FOREIGN KEY ("resident_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."managers"
    ADD CONSTRAINT "managers_condo_id_fkey" FOREIGN KEY ("condo_id") REFERENCES "public"."condos"("id");



ALTER TABLE ONLY "public"."managers"
    ADD CONSTRAINT "managers_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "public"."conversations"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."messages"
    ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."monthly_bills"
    ADD CONSTRAINT "monthly_bills_posted_by_fkey" FOREIGN KEY ("posted_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."monthly_bills"
    ADD CONSTRAINT "monthly_bills_received_by_fkey" FOREIGN KEY ("received_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."notifications"
    ADD CONSTRAINT "notifications_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."one_time_fees"
    ADD CONSTRAINT "one_time_fees_posted_by_fkey" FOREIGN KEY ("posted_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."one_time_fees"
    ADD CONSTRAINT "one_time_fees_received_by_fkey" FOREIGN KEY ("received_by") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."payment_proofs"
    ADD CONSTRAINT "payment_proofs_payment_id_fkey" FOREIGN KEY ("payment_id") REFERENCES "public"."payments"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payment_proofs"
    ADD CONSTRAINT "payment_proofs_uploaded_by_fkey" FOREIGN KEY ("uploaded_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_monthly_bill_id_fkey" FOREIGN KEY ("monthly_bill_id") REFERENCES "public"."monthly_bills"("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_one_time_fee_id_fkey" FOREIGN KEY ("one_time_fee_id") REFERENCES "public"."one_time_fees"("id");



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_paid_by_fkey" FOREIGN KEY ("paid_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."payments"
    ADD CONSTRAINT "payments_validated_by_fkey" FOREIGN KEY ("validated_by") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_auth_id_fkey" FOREIGN KEY ("auth_id") REFERENCES "auth"."users"("id");



ALTER TABLE ONLY "public"."residents"
    ADD CONSTRAINT "resident_memberships_unit_id_fkey" FOREIGN KEY ("unit_id") REFERENCES "public"."units"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."residents"
    ADD CONSTRAINT "residents_id_fkey" FOREIGN KEY ("id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."residents"
    ADD CONSTRAINT "residents_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id");



ALTER TABLE ONLY "public"."units"
    ADD CONSTRAINT "units_condo_id_fkey" FOREIGN KEY ("condo_id") REFERENCES "public"."condos"("id");



CREATE POLICY "Users can view own profile" ON "public"."profiles" FOR SELECT TO "authenticated" USING (("auth"."uid"() = "auth_id"));



ALTER TABLE "public"."announcements" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "announcements_delete_manager" ON "public"."announcements" FOR DELETE TO "authenticated" USING (("condo_id" = "public"."current_manager_condo_id"()));



CREATE POLICY "announcements_insert_manager" ON "public"."announcements" FOR INSERT TO "authenticated" WITH CHECK ((("condo_id" = "public"."current_manager_condo_id"()) AND ("posted_by" = "public"."current_profile_id"())));



CREATE POLICY "announcements_select_same_condo" ON "public"."announcements" FOR SELECT TO "authenticated" USING ((("condo_id" = "public"."current_manager_condo_id"()) OR ("condo_id" = "public"."current_resident_condo_id"())));



CREATE POLICY "announcements_update_manager" ON "public"."announcements" FOR UPDATE TO "authenticated" USING (("condo_id" = "public"."current_manager_condo_id"())) WITH CHECK ((("condo_id" = "public"."current_manager_condo_id"()) AND ("posted_by" = "public"."current_profile_id"())));



ALTER TABLE "public"."bills" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bills_delete_manager" ON "public"."bills" FOR DELETE TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."monthly_bills" "mb"
  WHERE (("mb"."id" = "bills"."monthly_bill_id") AND "public"."manager_can_access_resident"("mb"."received_by")))) OR (EXISTS ( SELECT 1
   FROM "public"."one_time_fees" "otf"
  WHERE (("otf"."id" = "bills"."one_time_fee_id") AND "public"."manager_can_access_resident"("otf"."received_by"))))));



CREATE POLICY "bills_insert_manager" ON "public"."bills" FOR INSERT TO "authenticated" WITH CHECK (((EXISTS ( SELECT 1
   FROM "public"."monthly_bills" "mb"
  WHERE (("mb"."id" = "bills"."monthly_bill_id") AND "public"."manager_can_access_resident"("mb"."received_by")))) OR (EXISTS ( SELECT 1
   FROM "public"."one_time_fees" "otf"
  WHERE (("otf"."id" = "bills"."one_time_fee_id") AND "public"."manager_can_access_resident"("otf"."received_by"))))));



CREATE POLICY "bills_select_same_context" ON "public"."bills" FOR SELECT TO "authenticated" USING (((EXISTS ( SELECT 1
   FROM "public"."monthly_bills" "mb"
  WHERE (("mb"."id" = "bills"."monthly_bill_id") AND (("mb"."received_by" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("mb"."received_by"))))) OR (EXISTS ( SELECT 1
   FROM "public"."one_time_fees" "otf"
  WHERE (("otf"."id" = "bills"."one_time_fee_id") AND (("otf"."received_by" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("otf"."received_by")))))));



ALTER TABLE "public"."condos" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "condos_insert_onboarding" ON "public"."condos" FOR INSERT TO "authenticated" WITH CHECK (true);



CREATE POLICY "condos_select_same_context" ON "public"."condos" FOR SELECT TO "authenticated" USING ((("id" = "public"."current_manager_condo_id"()) OR ("id" = "public"."current_resident_condo_id"())));



CREATE POLICY "condos_update_manager" ON "public"."condos" FOR UPDATE TO "authenticated" USING (("id" = "public"."current_manager_condo_id"())) WITH CHECK (("id" = "public"."current_manager_condo_id"()));



ALTER TABLE "public"."conversations" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "conversations_access" ON "public"."conversations" TO "authenticated" USING ("public"."current_profile_can_access_conversation"("manager_id", "resident_id")) WITH CHECK ("public"."current_profile_can_access_conversation"("manager_id", "resident_id"));



ALTER TABLE "public"."managers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "managers_own_access" ON "public"."managers" TO "authenticated" USING (("id" = "public"."current_profile_id"())) WITH CHECK (("id" = "public"."current_profile_id"()));



ALTER TABLE "public"."messages" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "messages_insert_conversation_access" ON "public"."messages" FOR INSERT TO "authenticated" WITH CHECK ((("sender_id" = "public"."current_profile_id"()) AND (EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "messages"."conversation_id") AND "public"."current_profile_can_access_conversation"("c"."manager_id", "c"."resident_id"))))));



CREATE POLICY "messages_select_conversation_access" ON "public"."messages" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."conversations" "c"
  WHERE (("c"."id" = "messages"."conversation_id") AND "public"."current_profile_can_access_conversation"("c"."manager_id", "c"."resident_id")))));



ALTER TABLE "public"."monthly_bills" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "monthly_bills_delete_manager" ON "public"."monthly_bills" FOR DELETE TO "authenticated" USING ("public"."manager_can_access_resident"("received_by"));



CREATE POLICY "monthly_bills_insert_manager" ON "public"."monthly_bills" FOR INSERT TO "authenticated" WITH CHECK ((("posted_by" = "public"."current_profile_id"()) AND "public"."manager_can_access_resident"("received_by")));



CREATE POLICY "monthly_bills_select_same_context" ON "public"."monthly_bills" FOR SELECT TO "authenticated" USING ((("received_by" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("received_by")));



CREATE POLICY "monthly_bills_update_manager" ON "public"."monthly_bills" FOR UPDATE TO "authenticated" USING ("public"."manager_can_access_resident"("received_by")) WITH CHECK ("public"."manager_can_access_resident"("received_by"));



ALTER TABLE "public"."notifications" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "notifications_own_access" ON "public"."notifications" TO "authenticated" USING (("profile_id" = "public"."current_profile_id"())) WITH CHECK (("profile_id" = "public"."current_profile_id"()));



ALTER TABLE "public"."one_time_fees" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "one_time_fees_delete_manager" ON "public"."one_time_fees" FOR DELETE TO "authenticated" USING ("public"."manager_can_access_resident"("received_by"));



CREATE POLICY "one_time_fees_insert_manager" ON "public"."one_time_fees" FOR INSERT TO "authenticated" WITH CHECK ((("posted_by" = "public"."current_profile_id"()) AND "public"."manager_can_access_resident"("received_by")));



CREATE POLICY "one_time_fees_select_same_context" ON "public"."one_time_fees" FOR SELECT TO "authenticated" USING ((("received_by" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("received_by")));



CREATE POLICY "one_time_fees_update_manager" ON "public"."one_time_fees" FOR UPDATE TO "authenticated" USING ("public"."manager_can_access_resident"("received_by")) WITH CHECK ("public"."manager_can_access_resident"("received_by"));



ALTER TABLE "public"."payment_proofs" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payment_proofs_insert_uploader" ON "public"."payment_proofs" FOR INSERT TO "authenticated" WITH CHECK ((("uploaded_by" = "public"."current_profile_id"()) AND (EXISTS ( SELECT 1
   FROM "public"."payments" "p"
  WHERE (("p"."id" = "payment_proofs"."payment_id") AND "public"."current_profile_can_access_payment"("p"."paid_by", "p"."monthly_bill_id", "p"."one_time_fee_id"))))));



CREATE POLICY "payment_proofs_select_same_context" ON "public"."payment_proofs" FOR SELECT TO "authenticated" USING ((EXISTS ( SELECT 1
   FROM "public"."payments" "p"
  WHERE (("p"."id" = "payment_proofs"."payment_id") AND "public"."current_profile_can_access_payment"("p"."paid_by", "p"."monthly_bill_id", "p"."one_time_fee_id")))));



ALTER TABLE "public"."payments" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "payments_delete_manager" ON "public"."payments" FOR DELETE TO "authenticated" USING ("public"."current_manager_can_review_payment"("paid_by", "monthly_bill_id", "one_time_fee_id"));



CREATE POLICY "payments_insert_manager_decision" ON "public"."payments" FOR INSERT TO "authenticated" WITH CHECK ((("validated_by" = "public"."current_profile_id"()) AND "public"."current_manager_can_review_payment"("paid_by", "monthly_bill_id", "one_time_fee_id")));



CREATE POLICY "payments_insert_resident_pending" ON "public"."payments" FOR INSERT TO "authenticated" WITH CHECK ((("paid_by" = "public"."current_profile_id"()) AND ("status" = 'pending'::"text") AND ("validated_by" IS NULL) AND "public"."current_resident_can_submit_payment"("paid_by", "monthly_bill_id", "one_time_fee_id")));



CREATE POLICY "payments_select_same_context" ON "public"."payments" FOR SELECT TO "authenticated" USING ("public"."current_profile_can_access_payment"("paid_by", "monthly_bill_id", "one_time_fee_id"));



CREATE POLICY "payments_update_manager_decision" ON "public"."payments" FOR UPDATE TO "authenticated" USING ((("status" = 'pending'::"text") AND "public"."current_manager_can_review_payment"("paid_by", "monthly_bill_id", "one_time_fee_id"))) WITH CHECK ((("validated_by" = "public"."current_profile_id"()) AND ("status" = ANY (ARRAY['completed'::"text", 'rejected'::"text"])) AND (("status" = 'completed'::"text") OR (NULLIF(TRIM(BOTH FROM "rejection_reason"), ''::"text") IS NOT NULL)) AND "public"."current_manager_can_review_payment"("paid_by", "monthly_bill_id", "one_time_fee_id")));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles_insert_own_or_manager_resident" ON "public"."profiles" FOR INSERT TO "authenticated" WITH CHECK ((("auth_id" = "auth"."uid"()) OR (("role" = 'resident'::"public"."condo_role") AND ("auth_id" IS NULL) AND "public"."profile_is_manager"())));



CREATE POLICY "profiles_select_same_context" ON "public"."profiles" FOR SELECT TO "authenticated" USING ((("id" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("id") OR (EXISTS ( SELECT 1
   FROM "public"."managers" "m"
  WHERE (("m"."id" = "profiles"."id") AND ("m"."condo_id" = "public"."current_resident_condo_id"()))))));



CREATE POLICY "profiles_update_own_or_manager_resident" ON "public"."profiles" FOR UPDATE TO "authenticated" USING ((("id" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("id"))) WITH CHECK ((("id" = "public"."current_profile_id"()) OR (("role" = 'resident'::"public"."condo_role") AND "public"."manager_can_access_resident"("id"))));



ALTER TABLE "public"."residents" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "residents_insert_manager" ON "public"."residents" FOR INSERT TO "authenticated" WITH CHECK ((EXISTS ( SELECT 1
   FROM "public"."units" "u"
  WHERE (("u"."id" = "residents"."unit_id") AND ("u"."condo_id" = "public"."current_manager_condo_id"())))));



CREATE POLICY "residents_select_managers_same_condo" ON "public"."managers" FOR SELECT TO "authenticated" USING (("condo_id" = "public"."current_resident_condo_id"()));



CREATE POLICY "residents_select_same_context" ON "public"."residents" FOR SELECT TO "authenticated" USING ((("id" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("id")));



CREATE POLICY "residents_update_same_context" ON "public"."residents" FOR UPDATE TO "authenticated" USING ((("id" = "public"."current_profile_id"()) OR "public"."manager_can_access_resident"("id"))) WITH CHECK ((("id" = "public"."current_profile_id"()) OR (EXISTS ( SELECT 1
   FROM "public"."units" "u"
  WHERE (("u"."id" = "residents"."unit_id") AND ("u"."condo_id" = "public"."current_manager_condo_id"()))))));



ALTER TABLE "public"."units" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "units_delete_manager_empty" ON "public"."units" FOR DELETE TO "authenticated" USING ((("condo_id" = "public"."current_manager_condo_id"()) AND (NOT (EXISTS ( SELECT 1
   FROM "public"."residents" "r"
  WHERE (("r"."unit_id" = "units"."id") AND ("r"."status" = 'active'::"public"."resident_status")))))));



CREATE POLICY "units_insert_manager" ON "public"."units" FOR INSERT TO "authenticated" WITH CHECK (("condo_id" = "public"."current_manager_condo_id"()));



CREATE POLICY "units_select_same_condo" ON "public"."units" FOR SELECT TO "authenticated" USING ((("condo_id" = "public"."current_manager_condo_id"()) OR ("condo_id" = "public"."current_resident_condo_id"())));



CREATE POLICY "units_update_manager" ON "public"."units" FOR UPDATE TO "authenticated" USING (("condo_id" = "public"."current_manager_condo_id"())) WITH CHECK (("condo_id" = "public"."current_manager_condo_id"()));



GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";



GRANT ALL ON FUNCTION "public"."claim_resident_profile"("p_condo_code" "text", "p_resident_code" "text", "p_auth_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."claim_resident_profile"("p_condo_code" "text", "p_resident_code" "text", "p_auth_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."claim_resident_profile"("p_condo_code" "text", "p_resident_code" "text", "p_auth_id" "uuid") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") TO "anon";
GRANT ALL ON FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_announcement"("p_title" "text", "p_content" "text", "p_category" "public"."announcement_category") TO "service_role";



REVOKE ALL ON FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."create_resident_profile"("p_first_name" "text", "p_last_name" "text", "p_unit_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."current_manager_can_access_bill_receiver"("p_received_by" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."current_manager_can_access_bill_receiver"("p_received_by" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_manager_can_access_bill_receiver"("p_received_by" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."current_manager_can_access_resident"("p_resident_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."current_manager_can_access_resident"("p_resident_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_manager_can_access_resident"("p_resident_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."current_manager_can_review_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."current_manager_can_review_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_manager_can_review_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."current_manager_condo_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_manager_condo_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."current_profile_can_access_conversation"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."current_profile_can_access_conversation"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_profile_can_access_conversation"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."current_profile_can_access_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."current_profile_can_access_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_profile_can_access_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."current_profile_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_profile_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."current_profile_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."current_profile_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_profile_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."current_resident_can_submit_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "anon";
GRANT ALL ON FUNCTION "public"."current_resident_can_submit_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_resident_can_submit_payment"("p_paid_by" "uuid", "p_monthly_bill_id" bigint, "p_one_time_fee_id" bigint) TO "service_role";



GRANT ALL ON FUNCTION "public"."current_resident_condo_id"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."current_resident_condo_id"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";



GRANT ALL ON FUNCTION "public"."manager_can_access_resident"("p_resident_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."manager_can_access_resident"("p_resident_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."manager_can_access_resident"("p_resident_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."manager_resident_same_condo"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "anon";
GRANT ALL ON FUNCTION "public"."manager_resident_same_condo"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."manager_resident_same_condo"("p_manager_id" "uuid", "p_resident_id" "uuid") TO "service_role";



GRANT ALL ON FUNCTION "public"."profile_is_manager"() TO "anon";
GRANT ALL ON FUNCTION "public"."profile_is_manager"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."profile_is_manager"() TO "service_role";



GRANT ALL ON FUNCTION "public"."profile_is_resident"() TO "anon";
GRANT ALL ON FUNCTION "public"."profile_is_resident"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."profile_is_resident"() TO "service_role";



REVOKE ALL ON FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text", "p_description" "text", "p_image_url" "text", "p_gallery_urls" "text"[]) FROM PUBLIC;
GRANT ALL ON FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text", "p_description" "text", "p_image_url" "text", "p_gallery_urls" "text"[]) TO "anon";
GRANT ALL ON FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text", "p_description" "text", "p_image_url" "text", "p_gallery_urls" "text"[]) TO "authenticated";
GRANT ALL ON FUNCTION "public"."setup_manager_condo"("p_name" "text", "p_location" "text", "p_description" "text", "p_image_url" "text", "p_gallery_urls" "text"[]) TO "service_role";



GRANT ALL ON FUNCTION "public"."update_resident_profile"("p_resident_id" "uuid", "p_full_name" "text", "p_unit_id" integer) TO "authenticated";
GRANT ALL ON FUNCTION "public"."update_resident_profile"("p_resident_id" "uuid", "p_full_name" "text", "p_unit_id" integer) TO "service_role";



GRANT ALL ON FUNCTION "public"."vacate_resident"("p_resident_id" "uuid") TO "authenticated";
GRANT ALL ON FUNCTION "public"."vacate_resident"("p_resident_id" "uuid") TO "service_role";



GRANT ALL ON TABLE "public"."bills" TO "anon";
GRANT ALL ON TABLE "public"."bills" TO "authenticated";
GRANT ALL ON TABLE "public"."bills" TO "service_role";



GRANT ALL ON SEQUENCE "public"."Bills_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."Bills_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."Bills_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."announcements" TO "anon";
GRANT ALL ON TABLE "public"."announcements" TO "authenticated";
GRANT ALL ON TABLE "public"."announcements" TO "service_role";



GRANT ALL ON SEQUENCE "public"."announcements_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."announcements_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."announcements_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."condos" TO "anon";
GRANT ALL ON TABLE "public"."condos" TO "authenticated";
GRANT ALL ON TABLE "public"."condos" TO "service_role";



GRANT ALL ON SEQUENCE "public"."condos_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."condos_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."condos_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."conversations" TO "anon";
GRANT ALL ON TABLE "public"."conversations" TO "authenticated";
GRANT ALL ON TABLE "public"."conversations" TO "service_role";



GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."conversations_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."managers" TO "anon";
GRANT ALL ON TABLE "public"."managers" TO "authenticated";
GRANT ALL ON TABLE "public"."managers" TO "service_role";



GRANT ALL ON TABLE "public"."messages" TO "anon";
GRANT ALL ON TABLE "public"."messages" TO "authenticated";
GRANT ALL ON TABLE "public"."messages" TO "service_role";



GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."messages_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."monthly_bills" TO "anon";
GRANT ALL ON TABLE "public"."monthly_bills" TO "authenticated";
GRANT ALL ON TABLE "public"."monthly_bills" TO "service_role";



GRANT ALL ON SEQUENCE "public"."monthly_bills_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."monthly_bills_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."monthly_bills_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."notifications" TO "anon";
GRANT ALL ON TABLE "public"."notifications" TO "authenticated";
GRANT ALL ON TABLE "public"."notifications" TO "service_role";



GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."notifications_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."one_time_fees" TO "anon";
GRANT ALL ON TABLE "public"."one_time_fees" TO "authenticated";
GRANT ALL ON TABLE "public"."one_time_fees" TO "service_role";



GRANT ALL ON SEQUENCE "public"."one_time_fees_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."one_time_fees_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."one_time_fees_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."payment_proofs" TO "anon";
GRANT ALL ON TABLE "public"."payment_proofs" TO "authenticated";
GRANT ALL ON TABLE "public"."payment_proofs" TO "service_role";



GRANT ALL ON SEQUENCE "public"."payment_proofs_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."payment_proofs_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."payment_proofs_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."payments" TO "anon";
GRANT ALL ON TABLE "public"."payments" TO "authenticated";
GRANT ALL ON TABLE "public"."payments" TO "service_role";



GRANT ALL ON SEQUENCE "public"."payments_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."payments_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."payments_id_seq" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."residents" TO "anon";
GRANT ALL ON TABLE "public"."residents" TO "authenticated";
GRANT ALL ON TABLE "public"."residents" TO "service_role";



GRANT ALL ON TABLE "public"."units" TO "anon";
GRANT ALL ON TABLE "public"."units" TO "authenticated";
GRANT ALL ON TABLE "public"."units" TO "service_role";



GRANT ALL ON SEQUENCE "public"."units_id_seq" TO "anon";
GRANT ALL ON SEQUENCE "public"."units_id_seq" TO "authenticated";
GRANT ALL ON SEQUENCE "public"."units_id_seq" TO "service_role";



ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";







