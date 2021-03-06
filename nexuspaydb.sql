PGDMP     5    $                w         
   nexuspaydb    10.6    10.5     �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    17917 
   nexuspaydb    DATABASE     �   CREATE DATABASE nexuspaydb WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'English_United States.1252' LC_CTYPE = 'English_United States.1252';
    DROP DATABASE nexuspaydb;
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                  postgres    false    3                        3079    12924    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            �           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1                       1247    17919    available_services    TYPE     i   CREATE TYPE public.available_services AS ENUM (
    'MOBILE TOP-UP',
    'BILL PAY',
    'SEND MONEY'
);
 %   DROP TYPE public.available_services;
       public       postgres    false    3                       1247    17926 	   card_type    TYPE     �   CREATE TYPE public.card_type AS ENUM (
    'LOYALTY POINTS CARD',
    'DBBL CREDIT CARD',
    'DBBL DEBIT CARD',
    'ROCKET'
);
    DROP TYPE public.card_type;
       public       postgres    false    3            o           1247    17936    mobile_companies    TYPE     �   CREATE TYPE public.mobile_companies AS ENUM (
    'GRAMEENPHONE',
    'BANGLALINK',
    'ROBI',
    'TELETALK',
    'AIRTEL',
    'CITYCELL'
);
 #   DROP TYPE public.mobile_companies;
       public       postgres    false    3            r           1247    17950    service_account_type    TYPE     �   CREATE TYPE public.service_account_type AS ENUM (
    'MOBILE OPERATORS ACCOUNT',
    'BILLER ACCOUNT',
    'BANK ACCOUNT',
    'CARD'
);
 '   DROP TYPE public.service_account_type;
       public       postgres    false    3            �            1255    17959 C   add_dbbl_credit_card(integer, character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.add_dbbl_credit_card(input_user_id integer, input_card_no character varying, input_card_cvc character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
counter2 integer;
holder_name character varying;
BEGIN
SELECT count(*) into counter2
FROM dbbl_credit_cards
WHERE 		card_no = input_card_no
	  AND	card_cvc = input_card_cvc;
IF(counter2=1) THEN
	SELECT username into holder_name
	FROM users
	WHERE user_id =input_user_id;
	
	
	INSERT INTO public.cards(
	card_no, card_holder_name, card_expiry_date, user_id, card_type)
	VALUES (input_card_no, holder_name, current_date+ interval '3 years', input_user_id,'DBBL CREDIT CARD' );
	return TRUE;
ELSE
	RAISE NOTICE 'WRONG INFORMATION';
	return FALSE;
END IF;
END;$$;
 �   DROP FUNCTION public.add_dbbl_credit_card(input_user_id integer, input_card_no character varying, input_card_cvc character varying);
       public       postgres    false    1    3            �            1255    17960 U   add_dbbl_debit_card(character varying, character varying, character varying, integer)    FUNCTION     �  CREATE FUNCTION public.add_dbbl_debit_card(input_account_no character varying, input_card_no character varying, input_card_pin character varying, input_user_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
counter2 integer;
holder_name character varying;
BEGIN
SELECT count(*) into counter2
FROM dbbl_accounts
WHERE 		account_no =input_account_no
	  AND	card_no = input_card_no
	  AND	card_pin = input_card_pin;
IF(counter2=1) THEN
	SELECT username into holder_name
	FROM users
	WHERE user_id =input_user_id;
	
	
	INSERT INTO public.cards(
	card_no, card_holder_name, card_expiry_date, user_id, card_type)
	VALUES (input_card_no, holder_name, current_date+ interval '3 years', input_user_id,'DBBL DEBIT CARD' );
	
	INSERT INTO public.dbbl_debit_cards(
	card_no, dbbl_account_no)
	VALUES (input_card_no, input_account_no);
	
	return TRUE;
ELSE
	RAISE NOTICE 'WRONG INFORMATION';
	return FALSE;
END IF;
END;$$;
 �   DROP FUNCTION public.add_dbbl_debit_card(input_account_no character varying, input_card_no character varying, input_card_pin character varying, input_user_id integer);
       public       postgres    false    1    3            �            1255    17961 9   add_rocket(character varying, character varying, integer)    FUNCTION     $  CREATE FUNCTION public.add_rocket(input_mobile_no character varying, input_pin character varying, input_user_id integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
counter2 integer;
holder_name character varying;
last_card_no character varying;
new_card_no integer;
BEGIN
SELECT count(*) into counter2
FROM rocket_accounts
WHERE 		mobile_no =input_mobile_no
	  AND   pin = input_pin;
IF(counter2=1) THEN
	SELECT username into holder_name
	FROM users
	WHERE user_id =input_user_id;
	
	SELECT card_no into last_card_no FROM rocket_cards ORDER BY card_no DESC LIMIT 1;
   	new_card_no=(CAST(last_card_no AS INTEGER))+1;
   
	
	INSERT INTO public.cards(
	card_no, card_holder_name, card_expiry_date, user_id, card_type)
	VALUES (CAST(new_card_no AS character varying), holder_name, current_date+ interval '3 years', input_user_id,'ROCKET' );
	
	INSERT INTO public.rocket_cards(
	card_no, mobile_no)
	VALUES (CAST(new_card_no AS character varying), input_mobile_no);
	
	return TRUE;
ELSE
	RAISE NOTICE 'WRONG INFORMATION';
	return FALSE;
END IF;
END;$$;
 x   DROP FUNCTION public.add_rocket(input_mobile_no character varying, input_pin character varying, input_user_id integer);
       public       postgres    false    3    1            �            1255    17962    check_date_change()    FUNCTION        CREATE FUNCTION public.check_date_change() RETURNS boolean
    LANGUAGE plpgsql
    AS $$BEGIN
IF((SELECT EXTRACT(DAY FROM "timestamp") FROM transactions ORDER BY "timestamp" DESC LIMIT 1) <> (SELECT EXTRACT(DAY FROM CURRENT_DATE)))
 THEN return TRUE;
ELSE return FALSE;
END IF; 
END;$$;
 *   DROP FUNCTION public.check_date_change();
       public       postgres    false    3    1            �            1255    17963    check_month_change()    FUNCTION     %  CREATE FUNCTION public.check_month_change() RETURNS boolean
    LANGUAGE plpgsql
    AS $$BEGIN
IF((SELECT EXTRACT(MONTH FROM "timestamp") FROM transactions ORDER BY "timestamp" DESC LIMIT 1) <> (SELECT EXTRACT(MONTH FROM CURRENT_DATE)))
 THEN return TRUE;
ELSE return FALSE;
END IF; 
END;$$;
 +   DROP FUNCTION public.check_month_change();
       public       postgres    false    1    3            �            1255    17964     generating_loyalty_points_card()    FUNCTION       CREATE FUNCTION public.generating_loyalty_points_card() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
last_card_no character varying;
new_card_no integer;
BEGIN
   SELECT card_no into last_card_no FROM loyalty_points_cards ORDER BY card_no DESC LIMIT 1;
   new_card_no=(CAST(last_card_no AS INTEGER))+1;
   
	INSERT INTO public.cards(
	card_no, card_holder_name, card_expiry_date, user_id, card_type)
	VALUES (CAST(new_card_no AS character varying), NEW.username, current_date+interval '3 year', NEW.user_id, 'LOYALTY POINTS CARD');
					 
	INSERT INTO public.loyalty_points_cards(
	virtual_card_no, balance, exp_date, card_no)
	VALUES (CAST(new_card_no-390000 AS character varying), 0, current_date+interval '3 year', CAST(new_card_no AS character varying));

    return NEW; 
END$$;
 7   DROP FUNCTION public.generating_loyalty_points_card();
       public       postgres    false    1    3            �            1255    17965     is_valid_card(character varying)    FUNCTION     #  CREATE FUNCTION public.is_valid_card(given_card_no character varying) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
counter integer;
BEGIN
	SELECT COUNT(*) INTO counter
	FROM cards
	WHERE card_no=given_card_no;
	
	IF(counter>0) THEN return TRUE;
	ELSE return FALSE;
	END IF;
END;$$;
 E   DROP FUNCTION public.is_valid_card(given_card_no character varying);
       public       postgres    false    1    3            �            1255    18207 T   mobile_top_up(integer, character varying, double precision, public.mobile_companies)    FUNCTION     �  CREATE FUNCTION public.mobile_top_up(input_user_id integer, input_card_no character varying, input_amount double precision, input_mobile_operator public.mobile_companies) RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
input_card_type "card_type";
payee_account_no character varying;
input_service_no integer;
counter2 integer;
BEGIN

SELECT c1.card_type into input_card_type
FROM cards c1
WHERE user_id=input_user_id AND card_no=input_card_no;  

SELECT account_no INTO payee_account_no
FROM mobile_operator_accounts
WHERE mobile_operator_name=input_mobile_operator;

SELECT service_no INTO input_service_no
FROM services
WHERE service_name ='MOBILE TOP-UP';

SELECT count(*) INTO counter2
FROM services_accounts;

IF(input_amount<10) THEN
	RAISE NOTICE 'Low Amount';
	return False;
ELSE
	IF(input_card_type='LOYALTY POINTS CARD') THEN
		UPDATE 	loyalty_points_cards SET balance= balance-input_amount
		WHERE card_no = input_card_no;
	ELSIF(input_card_type='DBBL DEBIT CARD') THEN
		UPDATE 	dbbl_accounts SET balance= balance-input_amount
		WHERE card_no = input_card_no;
	ELSIF(input_card_type='DBBL CREDIT CARD') THEN
		UPDATE 	dbbl_credit_cards SET balance= balance-input_amount
		WHERE card_no = input_card_no;
	
	ELSE
		UPDATE 	rocket_accounts SET balance= balance-input_amount
		WHERE mobile_no=( 
			SELECT mobile_no
			FROM rocket_cards
			where	card_no = input_card_no
		);
	END IF;
	
	UPDATE 	mobile_operator_accounts SET balance= balance+input_amount
	WHERE account_no = payee_account_no;
	
	
	INSERT INTO public.services_accounts(
	services_account_id, service_no, service_account_type, service_acc)
	VALUES (counter2+1, input_service_no, 'MOBILE OPERATORS ACCOUNT', payee_account_no);
	INSERT INTO public.transactions(
	trx_id, "timestamp", payers_acc, payees_acc, amount, cashback, service_no)
	VALUES ( counter2+1,current_timestamp, input_card_no, counter2+1,input_amount, 0, input_service_no);
	RETURN TRUE;
END IF;

END;$$;
 �   DROP FUNCTION public.mobile_top_up(input_user_id integer, input_card_no character varying, input_amount double precision, input_mobile_operator public.mobile_companies);
       public       postgres    false    623    3    1            �            1255    17966    negative_balance()    FUNCTION     �   CREATE FUNCTION public.negative_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$BEGIN
   IF NEW.balance<0 THEN
      RAISE EXCEPTION 'balance negative';
   END IF;
   RETURN NEW;
END$$;
 )   DROP FUNCTION public.negative_balance();
       public       postgres    false    1    3            �            1255    17967    reset_daily_limit()    FUNCTION     �  CREATE FUNCTION public.reset_daily_limit() RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
checker boolean;
BEGIN
SELECT check_date_change() INTO checker;
IF checker = TRUE THEN UPDATE services SET daily_limit= 300 WHERE service_name = 'MOBILE TOP-UP';
					   UPDATE services SET daily_limit= 5000 WHERE service_name = 'SEND MONEY';
					   UPDATE services SET daily_limit= 2500 WHERE service_name = 'BILL PAY';
return TRUE;
ELSE return FALSE;
END IF;
END;$$;
 *   DROP FUNCTION public.reset_daily_limit();
       public       postgres    false    3    1            �            1255    17968    reset_monthly_limit()    FUNCTION     �  CREATE FUNCTION public.reset_monthly_limit() RETURNS boolean
    LANGUAGE plpgsql
    AS $$DECLARE
checker boolean;
BEGIN
SELECT check_month_change() INTO checker;
IF checker = TRUE THEN UPDATE services SET monthly_limit= 5000 WHERE service_name = 'MOBILE TOP-UP';
					   UPDATE services SET monthly_limit= 30000 WHERE service_name = 'SEND MONEY';
					   UPDATE services SET monthly_limit= 10000 WHERE service_name = 'BILL PAY';
return TRUE;
ELSE return FALSE;
END IF;
END;$$;
 ,   DROP FUNCTION public.reset_monthly_limit();
       public       postgres    false    1    3            �            1255    17969    update_mini_statement()    FUNCTION     �  CREATE FUNCTION public.update_mini_statement() RETURNS trigger
    LANGUAGE plpgsql
    AS $$DECLARE
counter2 integer;
payer_id character varying;
BEGIN
SELECT count(*) INTO counter2
FROM users_mini_statement;
counter2:=counter2+1;

SELECT user_id INTO payer_id
FROM cards
WHERE card_no = NEW.payers_acc;

INSERT INTO public.users_mini_statement(
	user_id, trx_id, mini_statement_id)
	VALUES (payer_id, NEW.trx_id, counter2);

END;$$;
 .   DROP FUNCTION public.update_mini_statement();
       public       postgres    false    3    1            �            1259    17970    biller_accounts    TABLE     �   CREATE TABLE public.biller_accounts (
    account_no character varying(20) NOT NULL,
    biller_name character varying(20) NOT NULL,
    balance double precision NOT NULL
);
 #   DROP TABLE public.biller_accounts;
       public         postgres    false    3            �            1259    17973    cards    TABLE     �   CREATE TABLE public.cards (
    card_no character varying(20) NOT NULL,
    card_holder_name character varying(20) NOT NULL,
    card_expiry_date date NOT NULL,
    user_id integer NOT NULL,
    card_type public.card_type
);
    DROP TABLE public.cards;
       public         postgres    false    3    541            �            1259    17976    dbbl_accounts    TABLE     �   CREATE TABLE public.dbbl_accounts (
    account_no character varying(20) NOT NULL,
    card_no character varying(20) NOT NULL,
    balance double precision NOT NULL,
    card_pin character varying(256) NOT NULL
);
 !   DROP TABLE public.dbbl_accounts;
       public         postgres    false    3            �            1259    17979    dbbl_credit_cards    TABLE     4  CREATE TABLE public.dbbl_credit_cards (
    card_no character varying NOT NULL,
    card_cvc character varying NOT NULL,
    balance double precision NOT NULL,
    loan_limit double precision NOT NULL,
    loan_pending double precision NOT NULL,
    bill_date date,
    interest double precision NOT NULL
);
 %   DROP TABLE public.dbbl_credit_cards;
       public         postgres    false    3            �            1259    17985    dbbl_debit_cards    TABLE     �   CREATE TABLE public.dbbl_debit_cards (
    card_no character varying(20) NOT NULL,
    dbbl_account_no character varying(20) NOT NULL
);
 $   DROP TABLE public.dbbl_debit_cards;
       public         postgres    false    3            �            1259    17988    loyalty_points_cards    TABLE     �   CREATE TABLE public.loyalty_points_cards (
    virtual_card_no character varying(20) NOT NULL,
    balance double precision NOT NULL,
    exp_date date NOT NULL,
    card_no character varying(20) NOT NULL
);
 (   DROP TABLE public.loyalty_points_cards;
       public         postgres    false    3            �            1259    17991    mobile_operator_accounts    TABLE     �   CREATE TABLE public.mobile_operator_accounts (
    mobile_operator_name public.mobile_companies NOT NULL,
    account_no character varying(20) NOT NULL,
    balance double precision NOT NULL
);
 ,   DROP TABLE public.mobile_operator_accounts;
       public         postgres    false    3    623            �            1259    17994    offers    TABLE     �   CREATE TABLE public.offers (
    offer_id integer NOT NULL,
    loyalty_points_card_no character varying(20) NOT NULL,
    cashback double precision NOT NULL,
    expiry_date date NOT NULL,
    payee_bank_account_no character varying NOT NULL
);
    DROP TABLE public.offers;
       public         postgres    false    3            �            1259    18000    rocket_accounts    TABLE       CREATE TABLE public.rocket_accounts (
    account_no character varying(20) NOT NULL,
    mobile_no character varying(14) NOT NULL,
    mobile_operator public.mobile_companies NOT NULL,
    balance double precision NOT NULL,
    pin character varying(256) NOT NULL
);
 #   DROP TABLE public.rocket_accounts;
       public         postgres    false    623    3            �            1259    18003    rocket_cards    TABLE        CREATE TABLE public.rocket_cards (
    card_no character varying(20) NOT NULL,
    mobile_no character varying(14) NOT NULL
);
     DROP TABLE public.rocket_cards;
       public         postgres    false    3            �            1259    18006    services    TABLE     �   CREATE TABLE public.services (
    service_no integer NOT NULL,
    service_name public.available_services NOT NULL,
    daily_limit double precision NOT NULL,
    monthly_limit double precision NOT NULL,
    user_id integer NOT NULL
);
    DROP TABLE public.services;
       public         postgres    false    538    3            �            1259    18009    services_accounts    TABLE     �   CREATE TABLE public.services_accounts (
    services_account_id integer NOT NULL,
    service_no integer NOT NULL,
    service_account_type public.service_account_type NOT NULL,
    service_acc character varying(20) NOT NULL
);
 %   DROP TABLE public.services_accounts;
       public         postgres    false    3    626            �            1259    18012 )   services_accounts_services_account_id_seq    SEQUENCE     �   CREATE SEQUENCE public.services_accounts_services_account_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 @   DROP SEQUENCE public.services_accounts_services_account_id_seq;
       public       postgres    false    3    207            �           0    0 )   services_accounts_services_account_id_seq    SEQUENCE OWNED BY     w   ALTER SEQUENCE public.services_accounts_services_account_id_seq OWNED BY public.services_accounts.services_account_id;
            public       postgres    false    208            �            1259    18014    services_bill_pay    TABLE     �   CREATE TABLE public.services_bill_pay (
    service_id integer NOT NULL,
    biller integer NOT NULL,
    amount double precision NOT NULL,
    main_service_no integer
);
 %   DROP TABLE public.services_bill_pay;
       public         postgres    false    3            �            1259    18017    services_mobile_top_ups    TABLE     �   CREATE TABLE public.services_mobile_top_ups (
    service_id integer NOT NULL,
    mobile_no character varying(14) NOT NULL,
    mobile_operator public.mobile_companies NOT NULL,
    amount integer NOT NULL,
    main_service_no integer NOT NULL
);
 +   DROP TABLE public.services_mobile_top_ups;
       public         postgres    false    623    3            �            1259    18020    services_send_money    TABLE     �   CREATE TABLE public.services_send_money (
    service_id integer NOT NULL,
    payee_card_no character varying(20) NOT NULL,
    amount double precision NOT NULL,
    main_service_no integer NOT NULL
);
 '   DROP TABLE public.services_send_money;
       public         postgres    false    3            �            1259    18023    transactions    TABLE     +  CREATE TABLE public.transactions (
    trx_id integer NOT NULL,
    "timestamp" timestamp with time zone NOT NULL,
    payers_acc character varying(20) NOT NULL,
    payees_acc integer NOT NULL,
    amount double precision NOT NULL,
    cashback double precision,
    service_no integer NOT NULL
);
     DROP TABLE public.transactions;
       public         postgres    false    3            �            1259    18026    transactions_trx_id_seq    SEQUENCE     �   CREATE SEQUENCE public.transactions_trx_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.transactions_trx_id_seq;
       public       postgres    false    212    3            �           0    0    transactions_trx_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.transactions_trx_id_seq OWNED BY public.transactions.trx_id;
            public       postgres    false    213            �            1259    18028    user_specific_billers    TABLE       CREATE TABLE public.user_specific_billers (
    biller_id integer NOT NULL,
    biller_name character varying(20) NOT NULL,
    user_id integer NOT NULL,
    biller_nick_name character varying(20) NOT NULL,
    biller_reference character varying(10) NOT NULL
);
 )   DROP TABLE public.user_specific_billers;
       public         postgres    false    3            �            1259    18031    users    TABLE       CREATE TABLE public.users (
    user_id integer NOT NULL,
    username character varying(30) NOT NULL,
    email character varying(50),
    mobile_no character varying(14) NOT NULL,
    mobile_operator public.mobile_companies NOT NULL,
    pin character varying(256) NOT NULL
);
    DROP TABLE public.users;
       public         postgres    false    3    623            �            1259    18034    users_mini_statement    TABLE     �   CREATE TABLE public.users_mini_statement (
    user_id integer NOT NULL,
    trx_id integer NOT NULL,
    mini_statement_id integer NOT NULL
);
 (   DROP TABLE public.users_mini_statement;
       public         postgres    false    3            �            1259    18037    users_user_id_seq    SEQUENCE     �   CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.users_user_id_seq;
       public       postgres    false    215    3            �           0    0    users_user_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;
            public       postgres    false    217            �
           2604    18039 %   services_accounts services_account_id    DEFAULT     �   ALTER TABLE ONLY public.services_accounts ALTER COLUMN services_account_id SET DEFAULT nextval('public.services_accounts_services_account_id_seq'::regclass);
 T   ALTER TABLE public.services_accounts ALTER COLUMN services_account_id DROP DEFAULT;
       public       postgres    false    208    207            �
           2604    18040    transactions trx_id    DEFAULT     z   ALTER TABLE ONLY public.transactions ALTER COLUMN trx_id SET DEFAULT nextval('public.transactions_trx_id_seq'::regclass);
 B   ALTER TABLE public.transactions ALTER COLUMN trx_id DROP DEFAULT;
       public       postgres    false    213    212            �
           2604    18041    users user_id    DEFAULT     n   ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);
 <   ALTER TABLE public.users ALTER COLUMN user_id DROP DEFAULT;
       public       postgres    false    217    215            �          0    17970    biller_accounts 
   TABLE DATA               K   COPY public.biller_accounts (account_no, biller_name, balance) FROM stdin;
    public       postgres    false    196   J�       �          0    17973    cards 
   TABLE DATA               `   COPY public.cards (card_no, card_holder_name, card_expiry_date, user_id, card_type) FROM stdin;
    public       postgres    false    197   ��       �          0    17976    dbbl_accounts 
   TABLE DATA               O   COPY public.dbbl_accounts (account_no, card_no, balance, card_pin) FROM stdin;
    public       postgres    false    198   ��       �          0    17979    dbbl_credit_cards 
   TABLE DATA               v   COPY public.dbbl_credit_cards (card_no, card_cvc, balance, loan_limit, loan_pending, bill_date, interest) FROM stdin;
    public       postgres    false    199   o�       �          0    17985    dbbl_debit_cards 
   TABLE DATA               D   COPY public.dbbl_debit_cards (card_no, dbbl_account_no) FROM stdin;
    public       postgres    false    200   ��       �          0    17988    loyalty_points_cards 
   TABLE DATA               [   COPY public.loyalty_points_cards (virtual_card_no, balance, exp_date, card_no) FROM stdin;
    public       postgres    false    201   !�       �          0    17991    mobile_operator_accounts 
   TABLE DATA               ]   COPY public.mobile_operator_accounts (mobile_operator_name, account_no, balance) FROM stdin;
    public       postgres    false    202   ��       �          0    17994    offers 
   TABLE DATA               p   COPY public.offers (offer_id, loyalty_points_card_no, cashback, expiry_date, payee_bank_account_no) FROM stdin;
    public       postgres    false    203   �       �          0    18000    rocket_accounts 
   TABLE DATA               _   COPY public.rocket_accounts (account_no, mobile_no, mobile_operator, balance, pin) FROM stdin;
    public       postgres    false    204   j�       �          0    18003    rocket_cards 
   TABLE DATA               :   COPY public.rocket_cards (card_no, mobile_no) FROM stdin;
    public       postgres    false    205   Z�       �          0    18006    services 
   TABLE DATA               a   COPY public.services (service_no, service_name, daily_limit, monthly_limit, user_id) FROM stdin;
    public       postgres    false    206   ��       �          0    18009    services_accounts 
   TABLE DATA               o   COPY public.services_accounts (services_account_id, service_no, service_account_type, service_acc) FROM stdin;
    public       postgres    false    207   3�       �          0    18014    services_bill_pay 
   TABLE DATA               X   COPY public.services_bill_pay (service_id, biller, amount, main_service_no) FROM stdin;
    public       postgres    false    209   ��       �          0    18017    services_mobile_top_ups 
   TABLE DATA               r   COPY public.services_mobile_top_ups (service_id, mobile_no, mobile_operator, amount, main_service_no) FROM stdin;
    public       postgres    false    210   ��       �          0    18020    services_send_money 
   TABLE DATA               a   COPY public.services_send_money (service_id, payee_card_no, amount, main_service_no) FROM stdin;
    public       postgres    false    211   �       �          0    18023    transactions 
   TABLE DATA               q   COPY public.transactions (trx_id, "timestamp", payers_acc, payees_acc, amount, cashback, service_no) FROM stdin;
    public       postgres    false    212   Q�       �          0    18028    user_specific_billers 
   TABLE DATA               t   COPY public.user_specific_billers (biller_id, biller_name, user_id, biller_nick_name, biller_reference) FROM stdin;
    public       postgres    false    214   ��       �          0    18031    users 
   TABLE DATA               Z   COPY public.users (user_id, username, email, mobile_no, mobile_operator, pin) FROM stdin;
    public       postgres    false    215   ��       �          0    18034    users_mini_statement 
   TABLE DATA               R   COPY public.users_mini_statement (user_id, trx_id, mini_statement_id) FROM stdin;
    public       postgres    false    216   ��       �           0    0 )   services_accounts_services_account_id_seq    SEQUENCE SET     X   SELECT pg_catalog.setval('public.services_accounts_services_account_id_seq', 1, false);
            public       postgres    false    208            �           0    0    transactions_trx_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.transactions_trx_id_seq', 1, false);
            public       postgres    false    213            �           0    0    users_user_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.users_user_id_seq', 13, true);
            public       postgres    false    217            �
           2606    18043 $   biller_accounts biller_accounts_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.biller_accounts
    ADD CONSTRAINT biller_accounts_pkey PRIMARY KEY (biller_name);
 N   ALTER TABLE ONLY public.biller_accounts DROP CONSTRAINT biller_accounts_pkey;
       public         postgres    false    196            �
           2606    18045 1   biller_accounts biller_accounts_unique_account_no 
   CONSTRAINT     r   ALTER TABLE ONLY public.biller_accounts
    ADD CONSTRAINT biller_accounts_unique_account_no UNIQUE (account_no);
 [   ALTER TABLE ONLY public.biller_accounts DROP CONSTRAINT biller_accounts_unique_account_no;
       public         postgres    false    196            �
           2606    18047    cards cards_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (card_no);
 :   ALTER TABLE ONLY public.cards DROP CONSTRAINT cards_pkey;
       public         postgres    false    197            �
           2606    18049 &   dbbl_accounts dbbl_account_card_no_key 
   CONSTRAINT     d   ALTER TABLE ONLY public.dbbl_accounts
    ADD CONSTRAINT dbbl_account_card_no_key UNIQUE (card_no);
 P   ALTER TABLE ONLY public.dbbl_accounts DROP CONSTRAINT dbbl_account_card_no_key;
       public         postgres    false    198            �
           2606    18051    dbbl_accounts dbbl_account_pkey 
   CONSTRAINT     e   ALTER TABLE ONLY public.dbbl_accounts
    ADD CONSTRAINT dbbl_account_pkey PRIMARY KEY (account_no);
 I   ALTER TABLE ONLY public.dbbl_accounts DROP CONSTRAINT dbbl_account_pkey;
       public         postgres    false    198            �
           2606    18053 (   dbbl_credit_cards dbbl_credit_cards_pkey 
   CONSTRAINT     k   ALTER TABLE ONLY public.dbbl_credit_cards
    ADD CONSTRAINT dbbl_credit_cards_pkey PRIMARY KEY (card_no);
 R   ALTER TABLE ONLY public.dbbl_credit_cards DROP CONSTRAINT dbbl_credit_cards_pkey;
       public         postgres    false    199            �
           2606    18055 %   dbbl_debit_cards dbbl_debit_card_pkey 
   CONSTRAINT     h   ALTER TABLE ONLY public.dbbl_debit_cards
    ADD CONSTRAINT dbbl_debit_card_pkey PRIMARY KEY (card_no);
 O   ALTER TABLE ONLY public.dbbl_debit_cards DROP CONSTRAINT dbbl_debit_card_pkey;
       public         postgres    false    200            �
           2606    18057 .   loyalty_points_cards loyalty_points_cards_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.loyalty_points_cards
    ADD CONSTRAINT loyalty_points_cards_pkey PRIMARY KEY (card_no);
 X   ALTER TABLE ONLY public.loyalty_points_cards DROP CONSTRAINT loyalty_points_cards_pkey;
       public         postgres    false    201            �
           2606    18059 @   mobile_operator_accounts mobile_operator_accounts_account_no_key 
   CONSTRAINT     �   ALTER TABLE ONLY public.mobile_operator_accounts
    ADD CONSTRAINT mobile_operator_accounts_account_no_key UNIQUE (account_no);
 j   ALTER TABLE ONLY public.mobile_operator_accounts DROP CONSTRAINT mobile_operator_accounts_account_no_key;
       public         postgres    false    202            �
           2606    18061 6   mobile_operator_accounts mobile_operator_accounts_pkey 
   CONSTRAINT     �   ALTER TABLE ONLY public.mobile_operator_accounts
    ADD CONSTRAINT mobile_operator_accounts_pkey PRIMARY KEY (mobile_operator_name);
 `   ALTER TABLE ONLY public.mobile_operator_accounts DROP CONSTRAINT mobile_operator_accounts_pkey;
       public         postgres    false    202            �
           2606    18063    offers offers_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_pkey PRIMARY KEY (offer_id);
 <   ALTER TABLE ONLY public.offers DROP CONSTRAINT offers_pkey;
       public         postgres    false    203            �
           2606    18065 ,   rocket_accounts rocket_account_mobile_no_key 
   CONSTRAINT     l   ALTER TABLE ONLY public.rocket_accounts
    ADD CONSTRAINT rocket_account_mobile_no_key UNIQUE (mobile_no);
 V   ALTER TABLE ONLY public.rocket_accounts DROP CONSTRAINT rocket_account_mobile_no_key;
       public         postgres    false    204            �
           2606    18067 #   rocket_accounts rocket_account_pkey 
   CONSTRAINT     i   ALTER TABLE ONLY public.rocket_accounts
    ADD CONSTRAINT rocket_account_pkey PRIMARY KEY (account_no);
 M   ALTER TABLE ONLY public.rocket_accounts DROP CONSTRAINT rocket_account_pkey;
       public         postgres    false    204            �
           2606    18069    rocket_cards rocket_cards_pkey 
   CONSTRAINT     a   ALTER TABLE ONLY public.rocket_cards
    ADD CONSTRAINT rocket_cards_pkey PRIMARY KEY (card_no);
 H   ALTER TABLE ONLY public.rocket_cards DROP CONSTRAINT rocket_cards_pkey;
       public         postgres    false    205            �
           2606    18071 '   services_bill_pay service_bill_pay_pkey 
   CONSTRAINT     m   ALTER TABLE ONLY public.services_bill_pay
    ADD CONSTRAINT service_bill_pay_pkey PRIMARY KEY (service_id);
 Q   ALTER TABLE ONLY public.services_bill_pay DROP CONSTRAINT service_bill_pay_pkey;
       public         postgres    false    209            �
           2606    18073 2   services_mobile_top_ups service_mobile_top_up_pkey 
   CONSTRAINT     x   ALTER TABLE ONLY public.services_mobile_top_ups
    ADD CONSTRAINT service_mobile_top_up_pkey PRIMARY KEY (service_id);
 \   ALTER TABLE ONLY public.services_mobile_top_ups DROP CONSTRAINT service_mobile_top_up_pkey;
       public         postgres    false    210            �
           2606    18075 +   services_send_money service_send_money_pkey 
   CONSTRAINT     q   ALTER TABLE ONLY public.services_send_money
    ADD CONSTRAINT service_send_money_pkey PRIMARY KEY (service_id);
 U   ALTER TABLE ONLY public.services_send_money DROP CONSTRAINT service_send_money_pkey;
       public         postgres    false    211            �
           2606    18077 (   services_accounts services_accounts_pkey 
   CONSTRAINT     w   ALTER TABLE ONLY public.services_accounts
    ADD CONSTRAINT services_accounts_pkey PRIMARY KEY (services_account_id);
 R   ALTER TABLE ONLY public.services_accounts DROP CONSTRAINT services_accounts_pkey;
       public         postgres    false    207            �
           2606    18079    services services_pkey 
   CONSTRAINT     \   ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_pkey PRIMARY KEY (service_no);
 @   ALTER TABLE ONLY public.services DROP CONSTRAINT services_pkey;
       public         postgres    false    206            �
           2606    18081    transactions transactions_pkey 
   CONSTRAINT     `   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_pkey PRIMARY KEY (trx_id);
 H   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_pkey;
       public         postgres    false    212                        2606    18083 0   user_specific_billers user_specific_billers_pkey 
   CONSTRAINT     u   ALTER TABLE ONLY public.user_specific_billers
    ADD CONSTRAINT user_specific_billers_pkey PRIMARY KEY (biller_id);
 Z   ALTER TABLE ONLY public.user_specific_billers DROP CONSTRAINT user_specific_billers_pkey;
       public         postgres    false    214                       2606    18085 .   users_mini_statement users_mini_statement_pkey 
   CONSTRAINT     {   ALTER TABLE ONLY public.users_mini_statement
    ADD CONSTRAINT users_mini_statement_pkey PRIMARY KEY (mini_statement_id);
 X   ALTER TABLE ONLY public.users_mini_statement DROP CONSTRAINT users_mini_statement_pkey;
       public         postgres    false    216                       2606    18206    users users_mobile_no_key 
   CONSTRAINT     Y   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_mobile_no_key UNIQUE (mobile_no);
 C   ALTER TABLE ONLY public.users DROP CONSTRAINT users_mobile_no_key;
       public         postgres    false    215                       2606    18087    users users_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);
 :   ALTER TABLE ONLY public.users DROP CONSTRAINT users_pkey;
       public         postgres    false    215                       2620    18088 &   dbbl_accounts balance_negative_checker    TRIGGER     �   CREATE TRIGGER balance_negative_checker BEFORE INSERT OR UPDATE ON public.dbbl_accounts FOR EACH ROW EXECUTE PROCEDURE public.negative_balance();
 ?   DROP TRIGGER balance_negative_checker ON public.dbbl_accounts;
       public       postgres    false    237    198                       2620    18089 *   dbbl_credit_cards balance_negative_checker    TRIGGER     �   CREATE TRIGGER balance_negative_checker BEFORE INSERT OR UPDATE ON public.dbbl_credit_cards FOR EACH ROW EXECUTE PROCEDURE public.negative_balance();
 C   DROP TRIGGER balance_negative_checker ON public.dbbl_credit_cards;
       public       postgres    false    199    237                       2620    18090 -   loyalty_points_cards balance_negative_checker    TRIGGER     �   CREATE TRIGGER balance_negative_checker BEFORE INSERT OR UPDATE ON public.loyalty_points_cards FOR EACH ROW EXECUTE PROCEDURE public.negative_balance();
 F   DROP TRIGGER balance_negative_checker ON public.loyalty_points_cards;
       public       postgres    false    201    237                        2620    18091 1   mobile_operator_accounts balance_negative_checker    TRIGGER     �   CREATE TRIGGER balance_negative_checker BEFORE INSERT OR UPDATE ON public.mobile_operator_accounts FOR EACH ROW EXECUTE PROCEDURE public.negative_balance();
 J   DROP TRIGGER balance_negative_checker ON public.mobile_operator_accounts;
       public       postgres    false    202    237            !           2620    18092 (   rocket_accounts balance_negative_checker    TRIGGER     �   CREATE TRIGGER balance_negative_checker BEFORE INSERT OR UPDATE ON public.rocket_accounts FOR EACH ROW EXECUTE PROCEDURE public.negative_balance();
 A   DROP TRIGGER balance_negative_checker ON public.rocket_accounts;
       public       postgres    false    204    237            #           2620    18093 #   users loaylty_points_card_generator    TRIGGER     �   CREATE TRIGGER loaylty_points_card_generator AFTER INSERT ON public.users FOR EACH ROW EXECUTE PROCEDURE public.generating_loyalty_points_card();
 <   DROP TRIGGER loaylty_points_card_generator ON public.users;
       public       postgres    false    235    215            "           2620    18208    transactions update_mini_stats    TRIGGER     �   CREATE TRIGGER update_mini_stats AFTER INSERT ON public.transactions FOR EACH STATEMENT EXECUTE PROCEDURE public.update_mini_statement();

ALTER TABLE public.transactions DISABLE TRIGGER update_mini_stats;
 7   DROP TRIGGER update_mini_stats ON public.transactions;
       public       postgres    false    212    240                       2606    18095    cards cards_user_id_fkey    FK CONSTRAINT     |   ALTER TABLE ONLY public.cards
    ADD CONSTRAINT cards_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 B   ALTER TABLE ONLY public.cards DROP CONSTRAINT cards_user_id_fkey;
       public       postgres    false    197    215    2820                       2606    18100 -   dbbl_debit_cards dbbl_debit_card_card_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dbbl_debit_cards
    ADD CONSTRAINT dbbl_debit_card_card_no_fkey FOREIGN KEY (card_no) REFERENCES public.cards(card_no);
 W   ALTER TABLE ONLY public.dbbl_debit_cards DROP CONSTRAINT dbbl_debit_card_card_no_fkey;
       public       postgres    false    197    200    2780            	           2606    18105 5   dbbl_debit_cards dbbl_debit_card_dbbl_account_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.dbbl_debit_cards
    ADD CONSTRAINT dbbl_debit_card_dbbl_account_no_fkey FOREIGN KEY (dbbl_account_no) REFERENCES public.dbbl_accounts(account_no);
 _   ALTER TABLE ONLY public.dbbl_debit_cards DROP CONSTRAINT dbbl_debit_card_dbbl_account_no_fkey;
       public       postgres    false    2784    198    200            
           2606    18110 6   loyalty_points_cards loyalty_points_cards_card_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.loyalty_points_cards
    ADD CONSTRAINT loyalty_points_cards_card_no_fkey FOREIGN KEY (card_no) REFERENCES public.cards(card_no);
 `   ALTER TABLE ONLY public.loyalty_points_cards DROP CONSTRAINT loyalty_points_cards_card_no_fkey;
       public       postgres    false    201    197    2780                       2606    18115 )   offers offers_loyalty_points_card_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_loyalty_points_card_no_fkey FOREIGN KEY (loyalty_points_card_no) REFERENCES public.loyalty_points_cards(card_no);
 S   ALTER TABLE ONLY public.offers DROP CONSTRAINT offers_loyalty_points_card_no_fkey;
       public       postgres    false    2790    203    201                       2606    18120 (   offers offers_payee_bank_account_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.offers
    ADD CONSTRAINT offers_payee_bank_account_no_fkey FOREIGN KEY (payee_bank_account_no) REFERENCES public.biller_accounts(account_no);
 R   ALTER TABLE ONLY public.offers DROP CONSTRAINT offers_payee_bank_account_no_fkey;
       public       postgres    false    203    196    2778                       2606    18125 &   rocket_cards rocket_cards_card_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.rocket_cards
    ADD CONSTRAINT rocket_cards_card_no_fkey FOREIGN KEY (card_no) REFERENCES public.cards(card_no);
 P   ALTER TABLE ONLY public.rocket_cards DROP CONSTRAINT rocket_cards_card_no_fkey;
       public       postgres    false    205    2780    197                       2606    18130 (   rocket_cards rocket_cards_mobile_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.rocket_cards
    ADD CONSTRAINT rocket_cards_mobile_no_fkey FOREIGN KEY (mobile_no) REFERENCES public.rocket_accounts(mobile_no);
 R   ALTER TABLE ONLY public.rocket_cards DROP CONSTRAINT rocket_cards_mobile_no_fkey;
       public       postgres    false    205    204    2798                       2606    18135 .   services_bill_pay service_bill_pay_biller_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_bill_pay
    ADD CONSTRAINT service_bill_pay_biller_fkey FOREIGN KEY (biller) REFERENCES public.user_specific_billers(biller_id);
 X   ALTER TABLE ONLY public.services_bill_pay DROP CONSTRAINT service_bill_pay_biller_fkey;
       public       postgres    false    214    2816    209                       2606    18140 W   services_mobile_top_ups service_mobile_top_ups_mobile_operator_accounts_mobile_operator    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_mobile_top_ups
    ADD CONSTRAINT service_mobile_top_ups_mobile_operator_accounts_mobile_operator FOREIGN KEY (mobile_operator) REFERENCES public.mobile_operator_accounts(mobile_operator_name);
 �   ALTER TABLE ONLY public.services_mobile_top_ups DROP CONSTRAINT service_mobile_top_ups_mobile_operator_accounts_mobile_operator;
       public       postgres    false    210    202    2794                       2606    18145 9   services_send_money service_send_money_payee_card_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_send_money
    ADD CONSTRAINT service_send_money_payee_card_no_fkey FOREIGN KEY (payee_card_no) REFERENCES public.cards(card_no);
 c   ALTER TABLE ONLY public.services_send_money DROP CONSTRAINT service_send_money_payee_card_no_fkey;
       public       postgres    false    2780    211    197                       2606    18150 3   services_accounts services_accounts_service_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_accounts
    ADD CONSTRAINT services_accounts_service_no_fkey FOREIGN KEY (service_no) REFERENCES public.services(service_no);
 ]   ALTER TABLE ONLY public.services_accounts DROP CONSTRAINT services_accounts_service_no_fkey;
       public       postgres    false    206    207    2804                       2606    18155 8   services_bill_pay services_bill_pay_main_service_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_bill_pay
    ADD CONSTRAINT services_bill_pay_main_service_no_fkey FOREIGN KEY (main_service_no) REFERENCES public.services(service_no);
 b   ALTER TABLE ONLY public.services_bill_pay DROP CONSTRAINT services_bill_pay_main_service_no_fkey;
       public       postgres    false    206    209    2804                       2606    18160 D   services_mobile_top_ups services_mobile_top_ups_main_service_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_mobile_top_ups
    ADD CONSTRAINT services_mobile_top_ups_main_service_no_fkey FOREIGN KEY (main_service_no) REFERENCES public.services(service_no);
 n   ALTER TABLE ONLY public.services_mobile_top_ups DROP CONSTRAINT services_mobile_top_ups_main_service_no_fkey;
       public       postgres    false    206    210    2804                       2606    18165 <   services_send_money services_send_money_main_service_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services_send_money
    ADD CONSTRAINT services_send_money_main_service_no_fkey FOREIGN KEY (main_service_no) REFERENCES public.services(service_no);
 f   ALTER TABLE ONLY public.services_send_money DROP CONSTRAINT services_send_money_main_service_no_fkey;
       public       postgres    false    206    211    2804                       2606    18170    services services_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.services
    ADD CONSTRAINT services_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 H   ALTER TABLE ONLY public.services DROP CONSTRAINT services_user_id_fkey;
       public       postgres    false    215    206    2820                       2606    18175 )   transactions transactions_payees_acc_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_payees_acc_fkey FOREIGN KEY (payees_acc) REFERENCES public.services_accounts(services_account_id);
 S   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_payees_acc_fkey;
       public       postgres    false    212    2806    207                       2606    18180 )   transactions transactions_payers_acc_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_payers_acc_fkey FOREIGN KEY (payers_acc) REFERENCES public.cards(card_no);
 S   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_payers_acc_fkey;
       public       postgres    false    197    212    2780                       2606    18185 )   transactions transactions_service_no_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.transactions
    ADD CONSTRAINT transactions_service_no_fkey FOREIGN KEY (service_no) REFERENCES public.services(service_no);
 S   ALTER TABLE ONLY public.transactions DROP CONSTRAINT transactions_service_no_fkey;
       public       postgres    false    212    2804    206                       2606    18190 <   user_specific_billers user_specific_billers_biller_name_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_specific_billers
    ADD CONSTRAINT user_specific_billers_biller_name_fkey FOREIGN KEY (biller_name) REFERENCES public.biller_accounts(biller_name);
 f   ALTER TABLE ONLY public.user_specific_billers DROP CONSTRAINT user_specific_billers_biller_name_fkey;
       public       postgres    false    196    214    2776                       2606    18195 8   user_specific_billers user_specific_billers_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.user_specific_billers
    ADD CONSTRAINT user_specific_billers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 b   ALTER TABLE ONLY public.user_specific_billers DROP CONSTRAINT user_specific_billers_user_id_fkey;
       public       postgres    false    214    2820    215                       2606    18200 6   users_mini_statement users_mini_statement_user_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY public.users_mini_statement
    ADD CONSTRAINT users_mini_statement_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);
 `   ALTER TABLE ONLY public.users_mini_statement DROP CONSTRAINT users_mini_statement_user_id_fkey;
       public       postgres    false    2820    216    215            �   ~   x�m�=1D�ɏ�M�n��;�$��ͱ��׺ھ7̌��NMs���<�RX���@��X-^����\e�
7k�8G�X�4�p�q��f�^kb��t���A��SU;�	�Z�/�X9�>�8F�      �   �   x�u���0�sy
^ �m��(#�\L��g�������1ڄ�~@��$�(�=� Q�@�@	PV�E���M�\7[?[Թ�,��j�k�A� �ъ�!�\�zgKG�B��:���#R��D��i�gu�/K�5Ӕ,aBM�t�=͋t$ɄI��i���@�~���U�|ٳ���@?�hZ�NC����ᐆ\G�.�ơ�� �]cW���J��j�,�n�o]wԎ(�r�\�S���;���g��} *0��      �   ~   x�U�A!���*˲���Gú�d�%�"ZYm�����������^E���n��&v���>�]�e��M�$�|K��M���D[¶�%lK[¾�&om	���&ok�%�mж1������ �SI'      �   h   x�}�A� ��P��D_����j�u8�f6d��R�I�U"�k2nI�󫬴lҺRߤ���Od;�]�F��Ȣ+GW^�Md^���s�����0bm�j�� �e      �   *   x��4 CNC �e	b��F�1�mf �F\1z\\\ �q�      �   x   x�m�K!�5��	�����S��I�^,Đy�ڬdbVԊ+���K+�[�H>Z����Q\��'h�=T�\P��?UP���줂[3��}G�:eͶ���C,>g�z'�/��;�      �   ^   x�%�K
�0�usI�u�����J�F��簟��<f�B7szΜ�X��XD��ʕ��M")M;�	Q�Y��CI%��k�J���6�÷ ��m      �   C   x�]���@����"{�����1��RImdJ2&BΦh!�jFQ����^6?��68��{�P��H�X��      �   �   x�}���0�5|��<x-+i�X�6&��wʝdɜ޹-;G��ʭe��!��s-���nrv���u�N��u�N�韽�����.��w��Ũ��
��fՠ�4��U�z��koz��9�s�Bs98�0׃��;i�b�|�I��nLNFNrJ0��wy�2���83������n�!I@;z��˻R���ӻ1��0��ݘMFv�7b�G9�K��_��      �   0   x�37 cNCs0��L��L B�@!K��!D�(d����� M�
      �   �   x�u�1�0����� (v�� 2 �M$`���ρ���[�Lk�=�^��ޝR�T��`�(��g�<+`�L�1=�vk��~$Ŀ�#��#/Y{q��g�Bֽ�~�I�/�+�_0�!XV�EMCP|� �u9]F      �   U   x�3�4���w��qU�pr�
Vptv���4440�2�4�tvrᴴ4000�2�D�s�r��5��ˈ�� ��=... ��      �      x������ � �      �   W   x��1
�0 �9y�$��8VU�HG���|q2"23���ӽ�����q�3�`��sT��P���"b��V"���_�"~��      �   %   x�3�0 CNSNK.#׌�Hrs��qqq i�t      �   d   x�e�K� E�1��yc� ��մ�12�䂐BZ�D���]�B��1BB	�~�Dc��m� G����eR�4�O�ؗ�[����Y����5�#�      �   �   x�m�MO�0����c�Z�؅Y[��������JL���mV���i�w�p��b�~X��w�8jrl�҄!��t�I�Z<�Z���̽6����c�Ӣͤ����תBe�B֙��9���J�(�M��x����r�銠�O�ҿU��>Tn�P�+4XH^eh��ñ�zb8��C�67�o�U���|Z��y&p�0����\�]��A^^WE�m���?ȼ$�7�d+ԋ���Y�>�v�7i���      �   �   x�u�M��0Eד#��Iug*A�yUJ7�&������[F���0��Y܋��Ʋ���e�ޮ�`�	=�ue�+��]� �r&-���r��/�-)
ZRZ�̣R���:�;��λ���u=	=LlQ����_����������a"%�RJ���2:�P�Ϙ�18�s�����	ND����x{(!@������z�p����k3!���      �   (   x��9 0İ�����M��HT(�8eh�f���ޣ>K�/     