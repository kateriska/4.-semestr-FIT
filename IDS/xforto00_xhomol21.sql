-- Autori: Katerina Fortova (xforto00), Jaromir Homolka (xhomol21)
-- Ukol - IDS - Finalni databaze - Tema: Klub anonymnich alkoholiku

DROP TABLE Schuze CASCADE CONSTRAINTS;
DROP TABLE Formalni CASCADE CONSTRAINTS;
DROP TABLE Neformalni CASCADE CONSTRAINTS;
DROP TABLE Odbornik CASCADE CONSTRAINTS;
DROP TABLE Patron CASCADE CONSTRAINTS;
DROP TABLE Alkoholik CASCADE CONSTRAINTS;
DROP TABLE Kontrola CASCADE CONSTRAINTS;
DROP TABLE Poziti_alkoholu CASCADE CONSTRAINTS;

DROP SEQUENCE sekvence_schuze;
DROP SEQUENCE sekvence_alkoholik;
DROP SEQUENCE sekvence_patron;
DROP SEQUENCE sekvence_odbornik;
DROP SEQUENCE sekvence_kontrola;
DROP SEQUENCE sekvence_poziti;

DROP PROCEDURE procedura_zastoupeni_alkoholik;
DROP PROCEDURE procedura_detaily_kontrola;
DROP PROCEDURE napoveda;

-- VYTVORENI TABULEK:

-- vztah generalizace specializace - zdedene maji stejny primarni klic
CREATE TABLE Schuze (
    schuze_id INT PRIMARY KEY,
    datum_cas_konani TIMESTAMP NOT NULL
);

CREATE TABLE Formalni (
    schuze_id INT NOT NULL,
    misto_konani VARCHAR(50) NOT NULL,
    vedouci_konani VARCHAR(50) NOT NULL
);

CREATE TABLE Neformalni (
    schuze_id INT NOT NULL,
    misto_konani VARCHAR(50) NOT NULL,
    tel_cislo CHAR(9),
    CONSTRAINT kontrola_tel_cislo CHECK (tel_cislo NOT LIKE '%[^0-9]%')
);

-- vytvoreni dalsich tabulek
CREATE TABLE Odbornik (
    odbornik_id INT PRIMARY KEY,
    vek INTEGER NOT NULL,
    pohlavi_odbornik VARCHAR(20) NOT NULL, 
    mira_expertizy VARCHAR(50),
    dosazena_praxe VARCHAR(50),
    schuze_id_odbornik INT,
    CONSTRAINT FK_schuze_id_odbornik FOREIGN KEY (schuze_id_odbornik) REFERENCES Schuze(schuze_id)
);

CREATE TABLE Patron (
    patron_id INT PRIMARY KEY,
    vek INTEGER NOT NULL,
    pohlavi_patron VARCHAR(20) NOT NULL,
    schuze_id_patron INT,
    CONSTRAINT FK_schuze_id_patron FOREIGN KEY (schuze_id_patron) REFERENCES Schuze(schuze_id)
);

CREATE TABLE Alkoholik (
    alkoholik_id INT PRIMARY KEY,
    vek INTEGER NOT NULL,
    pohlavi_alkoholik VARCHAR(20) NOT NULL, 
    pocet_ucasti_na_sezeni INTEGER,
    schuze_id_alkoholik INT,
    patron_id_alkoholik INT, 
    CONSTRAINT FK_schuze_id_alkoholik FOREIGN KEY (schuze_id_alkoholik) REFERENCES Schuze(schuze_id),
    CONSTRAINT FK_patron_id_alkoholik FOREIGN KEY (patron_id_alkoholik) REFERENCES Patron(patron_id)
);


CREATE TABLE Kontrola (
    kontrola_id INT PRIMARY KEY,
    mira_alkoholu_v_krvi FLOAT,
    puvod_vypiteho_alkoholu VARCHAR(50),
    typ_alkoholu VARCHAR(20),
    odbornik_id_kontrola INT,
    alkoholik_id_kontrola INT, 
    CONSTRAINT FK_odbornik_id_kontrola FOREIGN KEY (odbornik_id_kontrola) REFERENCES Odbornik(odbornik_id),
    CONSTRAINT FK_alkoholik_id_kontrola FOREIGN KEY (alkoholik_id_kontrola) REFERENCES Alkoholik(alkoholik_id)
);


CREATE TABLE poziti_alkoholu (
    poziti_alkoholu_id INT PRIMARY KEY,
    datum_cas TIMESTAMP NOT NULL,
    puvod_vypiteho_alkoholu VARCHAR(50) NOT NULL,
    typ_alkoholu VARCHAR(20) NOT NULL,
    alkoholik_id_poziti INT, 
    CONSTRAINT FK_alkoholik_id_poziti FOREIGN KEY (alkoholik_id_poziti) REFERENCES Alkoholik(alkoholik_id)
);

-- TRIGGERY:

-- Trigger pro kontrolu spravnych lokaci pro formalni schuzi - muzou byt jen nejake z urciteho seznamu
CREATE OR REPLACE TRIGGER trigger_lokace_formalni BEFORE INSERT OR UPDATE OF misto_konani ON Formalni FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.misto_konani) IN ('hudeckova vila, brno', 'hotel edison, jihlava', 'nemocnice u svate anny, brno', 'pecovatelsky dum andrea, brno', 'stredni skola obora, prerov', 'centrum srdicko, zdar nad sazavou')
    THEN
    RAISE_APPLICATION_ERROR(-20000, 'Chyba - Nespravne umisteni lokace formalni schuze!');
  END IF;
END;
/
-- Triggery na kontrolu spravne zadaneho pohlavi 
CREATE OR REPLACE TRIGGER trigger_pohlavi_alkoholik BEFORE INSERT OR UPDATE OF pohlavi_alkoholik ON Alkoholik FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.pohlavi_alkoholik) IN ('muz', 'zena')
    THEN
    RAISE_APPLICATION_ERROR(-20001, 'Chyba - Zadano neplatne pohlavi u alkoholika!');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_pohlavi_patron BEFORE INSERT OR UPDATE OF pohlavi_patron ON Patron FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.pohlavi_patron) IN ('muz', 'zena')
    THEN
    RAISE_APPLICATION_ERROR(-20002, 'Chyba - Zadano neplatne pohlavi u patrona!');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_pohlavi_odbornik BEFORE INSERT OR UPDATE OF pohlavi_odbornik ON Odbornik FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.pohlavi_odbornik) IN ('muz', 'zena')
    THEN
    RAISE_APPLICATION_ERROR(-20003, 'Chyba - Zadano neplatne pohlavi u odbornika!');
  END IF;
END;
/

-- Trigger pro kontrolu spravne zadaneho jmena a prijmeni
CREATE OR REPLACE TRIGGER trigger_formalni_jmeno BEFORE INSERT OR UPDATE OF vedouci_konani ON Formalni FOR EACH ROW
BEGIN
    IF NOT REGEXP_LIKE(:NEW.vedouci_konani, '^[a-zA-Z ]*$')
    THEN
    RAISE_APPLICATION_ERROR(-20011, 'Chyba - Zadano neplatne jmeno a prijmeni');
 END IF;
END;
/

-- Trigger pro kontrolu typu alkoholu u kontroly a zapisu poziti alkoholu - muze byt jen nejaky z urciteho seznamu
CREATE OR REPLACE TRIGGER trigger_typ_kontrola BEFORE INSERT OR UPDATE OF typ_alkoholu ON Kontrola FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.typ_alkoholu) IN ('bile vino', 'cervene vino', 'ruzove vino', 'vino', 'pivo', 'svetly lezak', 'tmavy lezak', 'psenicne pivo', 'sekt', 'lihovina', 'destilat', 'liker', 'cider', 'michany napoj', 'rum', 'bily rum', 'tmavy rum', 'burcak', 'medovina', 'ostatni')
    THEN
    RAISE_APPLICATION_ERROR(-20012, 'Chyba - Zadan neplatny typ alkoholu u kontroly!');
  END IF;
END;
/

CREATE OR REPLACE TRIGGER trigger_typ_poziti BEFORE INSERT OR UPDATE OF typ_alkoholu ON Poziti_alkoholu FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.typ_alkoholu) IN ('bile vino', 'cervene vino', 'ruzove vino', 'vino', 'pivo', 'svetly lezak', 'tmavy lezak', 'psenicne pivo', 'sekt', 'lihovina', 'destilat', 'liker', 'cider', 'michany napoj', 'rum', 'bily rum', 'tmavy rum', 'burcak', 'medovina', 'ostatni')
    THEN
    RAISE_APPLICATION_ERROR(-20013, 'Chyba - Zadan neplatny typ alkoholu u poziti!');
  END IF;
END;
/

-- Trigger pro kontrolu miry expertizy u odbornika:
CREATE OR REPLACE TRIGGER trigger_mira_odbornik BEFORE INSERT OR UPDATE OF mira_expertizy ON Odbornik FOR EACH ROW
BEGIN
    IF NOT LOWER(:NEW.mira_expertizy) IN ('zakladni', 'stredni', 'vysoka', 'excelentni')
    THEN
    RAISE_APPLICATION_ERROR(-20014, 'Chyba - Zadan neplatny typ expertizy!');
  END IF;
END;
/

-- Triggery pro automaticke generovani hodnot primarniho klice ze sekvence pokud je nezadan
CREATE SEQUENCE sekvence_schuze START WITH 401 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_schuze_id BEFORE INSERT ON Schuze FOR EACH ROW
BEGIN
    :NEW.schuze_id := sekvence_schuze.NEXTVAL;
END;
/
CREATE SEQUENCE sekvence_alkoholik START WITH 001 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_alkoholik_id BEFORE INSERT ON Alkoholik FOR EACH ROW
BEGIN
    :NEW.alkoholik_id := sekvence_alkoholik.NEXTVAL;
END;
/
CREATE SEQUENCE sekvence_patron START WITH 101 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_patron_id BEFORE INSERT ON Patron FOR EACH ROW
BEGIN
    :NEW.patron_id := sekvence_patron.NEXTVAL;
END;
/
CREATE SEQUENCE sekvence_odbornik START WITH 201 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_odbornik_id BEFORE INSERT ON Odbornik FOR EACH ROW
BEGIN
    :NEW.odbornik_id := sekvence_odbornik.NEXTVAL;
END;
/
CREATE SEQUENCE sekvence_kontrola START WITH 501 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_kontrola_id BEFORE INSERT ON Kontrola FOR EACH ROW
BEGIN
    :NEW.kontrola_id := sekvence_kontrola.NEXTVAL;
END;
/
CREATE SEQUENCE sekvence_poziti START WITH 301 INCREMENT BY 1;
CREATE OR REPLACE TRIGGER trigger_generated_poziti_id BEFORE INSERT ON Poziti_alkoholu FOR EACH ROW
BEGIN
    :NEW.poziti_alkoholu_id := sekvence_poziti.NEXTVAL;
END;
/

-- PROCEDURY:

-- Procedura pocitajici procentualni zastoupeni muzu a zen u alkoholiku a procentualni zastoupeni ruznych vekovych skupin
CREATE OR REPLACE PROCEDURE procedura_zastoupeni_alkoholik AS
  CURSOR kurzor_alkoholik IS SELECT * FROM Alkoholik WHERE vek IS NOT NULL AND pohlavi_alkoholik IS NOT NULL;
  A Alkoholik%ROWTYPE;
  -- pocitadlo vsech alkoholiku
  counter INTEGER;
  -- pocitadlo muzu a zen u alkoholiku
  muz_counter INTEGER;
  zena_counter INTEGER;
  
  -- vekove kategorie alkoholiku
  alkoholik_0_17 INTEGER;
  alkoholik_18_29 INTEGER;
  alkoholik_30_39 INTEGER;
  alkoholik_40_49 INTEGER;
  alkoholik_50_59 INTEGER;
  alkoholik_60_69 INTEGER;
  alkoholik_70_79 INTEGER;
  alkoholik_80_89 INTEGER;
  alkoholik_90_vice INTEGER;
  
  BEGIN
  -- pocatecni inicializace
    counter := 0;
    
    muz_counter := 0;
    zena_counter := 0;
    
    alkoholik_0_17 := 0;
    alkoholik_18_29 := 0;
    alkoholik_30_39 := 0;
    alkoholik_40_49 := 0;
    alkoholik_50_59 := 0;
    alkoholik_60_69 := 0;
    alkoholik_70_79 := 0;
    alkoholik_80_89 := 0;
    alkoholik_90_vice := 0;
   

    OPEN kurzor_alkoholik;
    LOOP
      FETCH kurzor_alkoholik INTO A;
      
      EXIT WHEN kurzor_alkoholik%NOTFOUND; 
      counter := counter + 1;
      
      -- zjisteni pohlavi a zarazeni do kategorie muz nebo zena
      IF (LOWER(A.pohlavi_alkoholik) = 'muz') THEN muz_counter := muz_counter + 1;
      END IF;
      IF (LOWER(A.pohlavi_alkoholik) = 'zena') THEN zena_counter := zena_counter + 1;
      END IF;
      
      -- zjisteni veku a zarazeni do urcene vekove kategorie
      IF A.vek BETWEEN 0 AND 17 THEN alkoholik_0_17 := alkoholik_0_17 + 1; 
      END IF;
      IF A.vek BETWEEN 18 AND 29 THEN alkoholik_18_29 := alkoholik_18_29 + 1; 
      END IF;
      IF A.vek BETWEEN 30 AND 39 THEN alkoholik_30_39 := alkoholik_30_39 + 1; 
      END IF;
      IF A.vek BETWEEN 40 AND 49 THEN alkoholik_40_49 := alkoholik_40_49 + 1; 
      END IF;
      IF A.vek BETWEEN 50 AND 59 THEN alkoholik_50_59 := alkoholik_50_59 + 1; 
      END IF;
      IF A.vek BETWEEN 60 AND 69 THEN alkoholik_60_69 := alkoholik_60_69 + 1;
      END IF;
      IF A.vek BETWEEN 70 AND 79 THEN alkoholik_70_79 := alkoholik_70_79 + 1;
      END IF;
      IF A.vek BETWEEN 80 AND 89 THEN alkoholik_80_89 := alkoholik_80_89 + 1; 
      END IF;
      IF A.vek > 89 THEN alkoholik_90_vice := alkoholik_90_vice + 1; 
      END IF;
      
    END LOOP;
    
    -- vyjimka pokud je pocet alkoholiku nula
    IF counter = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;
    
    -- vypsani informaci, vypocteni procentualniho zastoupeni
    DBMS_OUTPUT.PUT_LINE('Zastoupeni muzu : ' || ROUND((muz_counter/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Zastoupeni zen  : ' || ROUND((zena_counter/counter)*100,3) || '%' );

    DBMS_OUTPUT.PUT_LINE('Alkoholici mladsi 18 let     : ' || ROUND((alkoholik_0_17/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 18 a 29 lety : ' || ROUND((alkoholik_18_29/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 30 a 39 lety : ' || ROUND((alkoholik_30_39/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 40 a 49 lety : ' || ROUND((alkoholik_40_49/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 50 a 59 lety : ' || ROUND((alkoholik_50_59/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 60 a 69 lety : ' || ROUND((alkoholik_60_69/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 70 a 79 lety : ' || ROUND((alkoholik_70_79/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici mezi 80 a 89 lety : ' || ROUND((alkoholik_80_89/counter)*100,3) || '%' );
    DBMS_OUTPUT.PUT_LINE('Alkoholici starsi 89 let     : ' || ROUND((alkoholik_90_vice/counter)*100,3) || '%' );
    
    
    CLOSE kurzor_alkoholik;
    -- osetreni vyjimek
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
     RAISE_APPLICATION_ERROR(-20004, 'Chyba - Nejsou zadani zadni alkoholici!');
    WHEN OTHERS THEN
     RAISE_APPLICATION_ERROR(-20005, 'Chyba - Procedura 1 byla neocekavane ukoncena!');
  END;
/
 
--Procedura vypisujici dodatecne informace o kontrole, ktera je zavolana
CREATE OR REPLACE PROCEDURE procedura_detaily_kontrola (procedura2_kontrola Kontrola.kontrola_id%TYPE) AS
  procedura2_kontrola_id Kontrola.kontrola_id%TYPE;
  procedura2_alkoholik_id Kontrola.alkoholik_id_kontrola%TYPE;
  procedura2_odbornik_id Kontrola.odbornik_id_kontrola%TYPE;
  procedura2_mira Kontrola.mira_alkoholu_v_krvi%TYPE;
  procedura2_puvod Kontrola.puvod_vypiteho_alkoholu%TYPE;
  procedura2_typ Kontrola.typ_alkoholu%TYPE;
  BEGIN
  -- vytvoreni SELECT dotazu a naplneni promennych potrebnymi udaji z tabulek
    SELECT K.kontrola_id, K.alkoholik_id_kontrola, K.odbornik_id_kontrola, K.mira_alkoholu_v_krvi, K.puvod_vypiteho_alkoholu, K.typ_alkoholu
    INTO procedura2_kontrola_id, procedura2_alkoholik_id, procedura2_odbornik_id, procedura2_mira, procedura2_puvod, procedura2_typ
    FROM Kontrola K
    WHERE K.kontrola_id = procedura2_kontrola;
    
    -- vypsani informaci o kontrole
    
    DBMS_OUTPUT.PUT_LINE('Kontrola cislo : ' || procedura2_kontrola_id);
    DBMS_OUTPUT.PUT_LINE('ID alkoholika  : ' || procedura2_alkoholik_id);
    DBMS_OUTPUT.PUT_LINE('ID odbornika   : ' || procedura2_odbornik_id);
    DBMS_OUTPUT.PUT_LINE('Mira vypiteho alkoholu  : ' || procedura2_mira || '‰' );
    DBMS_OUTPUT.PUT_LINE('Puvod vypiteho alkoholu : ' || procedura2_puvod);
    DBMS_OUTPUT.PUT_LINE('Typ vypiteho alkoholu   : ' || procedura2_typ);
    
    -- osetreni vyjimek  
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20006, 'Chyba - Nejsou zadane zadne kontroly!');
     WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR(-20007, 'Chyba - Procedura 2 byla neocekavane ukoncena!');
  END;
/

-- Procedura vypisujici napovedu o urcenych lokalitach formalni schuze ze seznamu a urcenych typech alkoholu ze seznamu
CREATE OR REPLACE PROCEDURE napoveda 
AS 
BEGIN 
-- vypis napovedy pro uzivatele databaze

   DBMS_OUTPUT.PUT_LINE('Vitejte v databazi Klubu anonymnich alkoholiku Mondero, Brno');
   DBMS_OUTPUT.PUT_LINE('Napoveda pro urcite omezene objekty v databazi:');
   DBMS_OUTPUT.PUT_LINE('Urcena mista pro formalni schuze: hudeckova vila, brno, hotel edison, jihlava, nemocnice u svate anny, brno, pecovatelsky dum andrea, brno, stredni skola obora, prerov, centrum srdicko, zdar nad sazavou '); 
   DBMS_OUTPUT.PUT_LINE('Typy alkoholu: bile vino, cervene vino, ruzove vino, vino, pivo, svetly lezak, tmavy lezak, psenicne pivo, sekt, lihovina, destilat, liker, cider, michany napoj, rum, bily rum, tmavy rum, burcak, medovina, ostatni');
   DBMS_OUTPUT.PUT_LINE('Miry expertizy u odbornika: zakladni, stredni, vysoka, excelentni');
END; 
/

-- CIZI KLICE PRO GENERALIZACI/SPECIALIZACI:
ALTER TABLE Formalni ADD CONSTRAINT FK_SchuzeFormalni FOREIGN KEY (schuze_id) REFERENCES Schuze;
ALTER TABLE Neformalni ADD CONSTRAINT FK_SchuzeNeformalni FOREIGN KEY (schuze_id) REFERENCES Schuze;

-- NAPLNENI TABULEK MODELOVYMI UDAJI:
-- TEST TRIGGER GENEROVANI PK ZE SEKVENCE
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('12/05/2019 17:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('24/05/2019 15:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('26/05/2019 10:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('01/06/2019 18:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('02/05/2019 19:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('18/06/2019 20:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('13/07/2019 14:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('29/06/2019 10:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('12/07/2019 16:00', 'DD/MM/YYYY HH24:MI'));
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('21/06/2019 14:00', 'DD/MM/YYYY HH24:MI'));
--INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('21/08/2019 14:00', 'DD/MM/YYYY HH24:MI')); -- TEST TRIGGER JMENO URCENEHO MISTA
--INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('21/08/2019 14:00', 'DD/MM/YYYY HH24:MI')); -- TEST TRIGGER JMENO VEDOUCIHO

SELECT * FROM Schuze;

INSERT INTO Formalni VALUES (401, 'Hudeckova Vila, Brno', 'Aneta Kalivodova');
INSERT INTO Formalni VALUES (404, 'Hotel Edison, Jihlava', 'Ales Henych');
INSERT INTO Formalni VALUES (405, 'nemocnice u svate anny, brno', 'Katerina Kovalska');
INSERT INTO Formalni VALUES (408, 'centrum Srdicko, Zdar nad Sazavou', 'Nikola Topinkova');
INSERT INTO Formalni VALUES (410, 'pecovatelsky dum andrea, brno', 'Jan Maxian');
--INSERT INTO Formalni VALUES (411, 'neznamo', 'Ales Jindra'); -- TEST TRIGGER JMENO URCENEHO MISTA
--INSERT INTO Formalni VALUES (412, 'Hudeckova Vila, Brno', 'Ales59 Jindra'); -- TEST TRIGGER JMENO VEDOUCIHO

SELECT * FROM Formalni;

INSERT INTO Neformalni VALUES (402, 'Hotel Mariot, Prerov', 773256999);
INSERT INTO Neformalni VALUES (403, 'Spolecensky dum, Luhacovice', 756323044);
INSERT INTO Neformalni VALUES (406, 'Centrum OMEGA, Ceska', 756222997);
INSERT INTO Neformalni VALUES (407, 'Kavarna Rosekafe, Zdar nad Sazavou', 608666789);
INSERT INTO Neformalni VALUES (409, 'Kavarna Montano, Tisnov', 608555207);

SELECT * FROM Neformalni;

INSERT INTO Odbornik VALUES (201, 68, 'muz', 'vysoka', '12 let FN Motol Praha',401);
INSERT INTO Odbornik VALUES (202, 72, 'zena', 'excelentni', '20 let FN Motol Praha',404);
INSERT INTO Odbornik VALUES (203, 42, 'muz', 'stredni', '10 let Nemocnice Jindrichuv Hradec',405);
INSERT INTO Odbornik VALUES (204, 45, 'zena', 'excelentni', '21 let Nemocnice Prerov',401);
INSERT INTO Odbornik VALUES (205, 50, 'muz', 'stredni', '12 let Nemocnice Nove Mesto na Morave',401);
--INSERT INTO Odbornik VALUES (206, 50, 'muzzzz', 'stredni', '12 let Nemocnice Nove Mesto na Morave',401); -- TEST TRIGGER POHLAVI
--INSERT INTO Odbornik VALUES (207, 50, 'muz', 'uzasna', '12 let Nemocnice Nove Mesto na Morave',401); -- TEST TRIGGER EXPERTIZA

SELECT * FROM Odbornik;

INSERT INTO Patron VALUES (101, 48, 'zena',401);
INSERT INTO Patron VALUES (102, 35, 'muz',402);
INSERT INTO Patron VALUES (103, 56, 'zena',408);
INSERT INTO Patron VALUES (104, 29, 'muz',406);
INSERT INTO Patron VALUES (105, 55, 'muz',406);
INSERT INTO Patron VALUES (106, 73, 'zena',401);
INSERT INTO Patron VALUES (107, 51, 'muz',409);
INSERT INTO Patron VALUES (108, 63, 'zena',407);
INSERT INTO Patron VALUES (109, 40, 'zena',406);
INSERT INTO Patron VALUES (110, 24, 'muz',401);

SELECT * FROM Patron;

INSERT INTO Alkoholik VALUES (001, 23, 'muz', 1, 401, 102);
INSERT INTO Alkoholik VALUES (002, 35, 'zena', 3, 403, 101);
INSERT INTO Alkoholik VALUES (003, 44, 'muz', 1, 402, 103);
INSERT INTO Alkoholik VALUES (004, 40, 'zena', 4, 401, 101);
INSERT INTO Alkoholik VALUES (005, 17, 'muz', 1, 401, 101);
INSERT INTO Alkoholik VALUES (006, 51, 'muz', 2, 405, 110);
INSERT INTO Alkoholik VALUES (007, 65, 'muz', 1, 410, 107);
INSERT INTO Alkoholik VALUES (008, 33, 'zena', 2, 406, 104);
INSERT INTO Alkoholik VALUES (009, 15, 'muz', 1, 403, 104);
INSERT INTO Alkoholik VALUES (010, 71, 'zena', 1, 407, 101);
INSERT INTO Alkoholik VALUES (011, 22, 'muz', 1, 401, 102);
INSERT INTO Alkoholik VALUES (012, 35, 'zena', 3, 403, 107);
INSERT INTO Alkoholik VALUES (013, 46, 'muz', 1, 404, 105);
INSERT INTO Alkoholik VALUES (014, 40, 'zena', 4, 401, 104);
INSERT INTO Alkoholik VALUES (015, 50, 'muz', 1, 408, 105);
INSERT INTO Alkoholik VALUES (016, 51, 'muz', 2, 405, 103);
INSERT INTO Alkoholik VALUES (017, 81, 'muz', 1, 410, 106);
INSERT INTO Alkoholik VALUES (018, 33, 'zena', 2, 409, 109);
INSERT INTO Alkoholik VALUES (019, 90, 'muz', 1, 403, 101);
INSERT INTO Alkoholik VALUES (020, 71, 'zena', 1, 407, 108);


SELECT * FROM Alkoholik;

INSERT INTO Kontrola VALUES (501, 1.50, 'becherovka', 'liker',204, 001);
INSERT INTO Kontrola VALUES (502, 0.50, 'captain morgan', 'bily rum',201, 003);
INSERT INTO Kontrola VALUES (503, 0.25, 'tuzemak', 'tmavy rum',203, 002);
INSERT INTO Kontrola VALUES (504, 1.05, 'cuba libre', 'michany napoj',201, 004);
INSERT INTO Kontrola VALUES (505, 1.05, 'vodka amundsen', 'destilat',204, 011);
INSERT INTO Kontrola VALUES (506, 1.15, 'staropramen', 'pivo',204, 004);
INSERT INTO Kontrola VALUES (507, 1.05, 'carolines', 'liker',201, 004);
INSERT INTO Kontrola VALUES (508, 0.35, 'republica', 'tmavy rum',204, 004);
INSERT INTO Kontrola VALUES (509, 0.50, 'swimming pool', 'michany napoj',205, 004);
INSERT INTO Kontrola VALUES (510, 1.05, 'kingswood', 'cider',202, 004);
INSERT INTO Kontrola VALUES (511, 1.05, 'rebel', 'pivo',205, 004);
INSERT INTO Kontrola VALUES (512, 1.20, 'cuba libre', 'michany napoj',201, 004);
--INSERT INTO Kontrola VALUES (514, 1.20, 'cuba libre', 'michan',201, 004); -- TEST TRIGGER TYP ALKOHOLU

SELECT * FROM kontrola;


INSERT INTO Poziti_alkoholu VALUES (301,TO_DATE('11/04/2019 23:00', 'DD/MM/YYYY HH24:MI'), 'rulandske sede', 'bile vino',002);
INSERT INTO Poziti_alkoholu VALUES (302,TO_DATE('11/04/2019 16:00', 'DD/MM/YYYY HH24:MI'), 'mojito', 'michany napoj',002);
INSERT INTO Poziti_alkoholu VALUES (303,TO_DATE('24/04/2019 17:00', 'DD/MM/YYYY HH24:MI'), 'long island ice tea', 'michany napoj',001);
INSERT INTO Poziti_alkoholu VALUES (304,TO_DATE('14/04/2019 18:00', 'DD/MM/YYYY HH24:MI'), 'becherovka', 'liker',001);
INSERT INTO Poziti_alkoholu VALUES (305,TO_DATE('18/04/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'high society', 'michany napoj',003);
INSERT INTO Poziti_alkoholu VALUES (305,TO_DATE('18/04/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'high society', 'michany napoj',011);
INSERT INTO Poziti_alkoholu VALUES (306,TO_DATE('16/04/2019 23:00', 'DD/MM/YYYY HH24:MI'), 'zlatopramen', 'pivo',003);
INSERT INTO Poziti_alkoholu VALUES (307,TO_DATE('14/04/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'becherovka', 'liker',007);
INSERT INTO Poziti_alkoholu VALUES (308,TO_DATE('18/04/2019 20:00', 'DD/MM/YYYY HH24:MI'), 'swimming pool', 'michany napoj',019);
INSERT INTO Poziti_alkoholu VALUES (309,TO_DATE('18/04/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'cosmopolitan', 'michany napoj',003);
INSERT INTO Poziti_alkoholu VALUES (310,TO_DATE('10/04/2019 16:00', 'DD/MM/YYYY HH24:MI'), 'malibu', 'liker',014);
INSERT INTO Poziti_alkoholu VALUES (311,TO_DATE('21/03/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'zelena', 'destilat',003);
INSERT INTO Poziti_alkoholu VALUES (312,TO_DATE('18/03/2019 17:00', 'DD/MM/YYYY HH24:MI'), 'bohemia sekt', 'sekt',010);
INSERT INTO Poziti_alkoholu VALUES (313,TO_DATE('18/03/2019 22:00', 'DD/MM/YYYY HH24:MI'), 'high society', 'michany napoj',0015);

SELECT * FROM Poziti_alkoholu;

-- SELECT DOTAZY:

-- SQL skript obsahujici dotazy SELECT musi obsahovat konkretni alespon dva dotazy vyuzivajici spojeni dvou tabulek:
-- Kteri alkoholici nebo odbornici maji vek mezi 40-50 lety?
SELECT odbornik_id AS id, vek, pohlavi_odbornik FROM Odbornik WHERE vek BETWEEN 40 AND 50
UNION
SELECT alkoholik_id AS id, vek, pohlavi_alkoholik FROM Alkoholik WHERE vek BETWEEN 40 AND 50;

-- Kteri patroni nebo odbornici jsou zeny?
SELECT odbornik_id AS id, pohlavi_odbornik FROM Odbornik WHERE pohlavi_odbornik='zena'
UNION
SELECT patron_id AS id, pohlavi_patron FROM Patron WHERE pohlavi_patron='zena';

--jeden vyuzivajici spojeni tri tabulek:
-- Kdo vsechno se ucastni schuze s id 401?
SELECT odbornik_id AS id, vek, pohlavi_odbornik FROM Odbornik WHERE schuze_id_odbornik=401
UNION
SELECT patron_id AS id , vek, pohlavi_patron FROM Patron WHERE schuze_id_patron=401
UNION
SELECT alkoholik_id AS id, vek, pohlavi_alkoholik FROM Alkoholik WHERE schuze_id_alkoholik=401;

--dva dotazy s klauzuli GROUP BY a agregacni funkci:
-- Kolik odborniku ma stredni miru expertizy?
SELECT mira_expertizy, COUNT(*) pocet_odborniku FROM Odbornik WHERE mira_expertizy='stredni' GROUP BY mira_expertizy ;
--- kolik poziti ma zapsan alkoholik s id 002, zobraz i informace o nem - id a puvod typ alkoholu
SELECT alkoholik_id_poziti alkoholik_id, puvod_vypiteho_alkoholu, typ_alkoholu, COUNT(*) pocet_poziti FROM Poziti_alkoholu WHERE alkoholik_id_poziti=002 GROUP BY alkoholik_id_poziti, puvod_vypiteho_alkoholu, typ_alkoholu;

--jeden dotaz obsahujici predikat EXISTS:
-- Kteri alkoholici si zaevidovali JEN poziti michaneho napoje?
SELECT DISTINCT A.* FROM Alkoholik A, Poziti_alkoholu P WHERE A.alkoholik_id = P.alkoholik_id_poziti AND P.typ_alkoholu = 'michany napoj' AND NOT EXISTS (SELECT * FROM Poziti_alkoholu P WHERE  A.alkoholik_id = P.alkoholik_id_poziti AND P.typ_alkoholu <> 'michany napoj');

--jeden dotaz s predikatem IN s vnorenym selectem (nikoliv IN s mnozinou konstantnich dat):
-- Kteri alkoholici pozili alkohol v breznu 2019?
SELECT * FROM Alkoholik WHERE alkoholik_id IN (SELECT alkoholik_id_poziti FROM Poziti_alkoholu WHERE datum_cas BETWEEN TO_DATE('01/03/2019 00:00', 'DD/MM/YYYY HH24:MI') AND TO_DATE('31/03/2019 23:59', 'DD/MM/YYYY HH24:MI'));

-- dalsi dotazy:
-- Kteri alkoholici se ucastni schuze s id 401?
SELECT alkoholik_id, vek, pohlavi_alkoholik FROM Alkoholik WHERE schuze_id_alkoholik=401;

-- Vyber z poziti_alkoholu udaje a serad podle data vzestupne
SELECT datum_cas, poziti_alkoholu_id FROM Poziti_alkoholu ORDER BY datum_cas ASC, poziti_alkoholu_id ASC;

-- VYKONANI PROCEDUR:
SET SERVEROUTPUT ON;

EXEC procedura_zastoupeni_alkoholik();

EXEC procedura_detaily_kontrola(504);
   
EXEC napoveda();

-- INDEX A EXPLAIN PLAN:
-- Kolik poctu poziti alkoholik zapsal?

-- Prvni volani bez pouziti indexu
EXPLAIN PLAN FOR
    SELECT A.alkoholik_id, A.vek, COUNT(*) AS pocet_poziti
    FROM Alkoholik A, Poziti_alkoholu P
    WHERE A.alkoholik_id = P.alkoholik_id_poziti
    GROUP BY A.alkoholik_id, A.vek;
    
SELECT plan_table_output FROM TABLE (dbms_xplan.display());

--Vytvoreni indexu
CREATE INDEX index_poziti_alkoholik ON poziti_alkoholu(alkoholik_id_poziti);

-- Opetovne zavolani s pouzitim indexu
EXPLAIN PLAN FOR
    SELECT A.alkoholik_id, A.vek, COUNT(*) AS pocet_poziti
    FROM Alkoholik A, Poziti_alkoholu P
    WHERE A.alkoholik_id = P.alkoholik_id_poziti
    GROUP BY A.alkoholik_id, A.vek;
    
SELECT plan_table_output FROM TABLE (dbms_xplan.display());

-- PRISTUPOVA PRAVA PRO DRUHEHO CLENA TYMU:

-- povoleni pro xhomol21 - xhomol21 je asistent co spravuje schuze v klubu 
GRANT SELECT ON Poziti_alkoholu TO xhomol21;
GRANT SELECT ON Kontrola TO xhomol21;
GRANT SELECT ON Patron TO xhomol21;
GRANT SELECT ON Alkoholik TO xhomol21;
GRANT SELECT ON Odbornik TO xhomol21;

GRANT ALL ON Schuze TO xhomol21;
GRANT ALL ON Formalni TO xhomol21;
GRANT ALL ON Neformalni TO xhomol21;

-- umozneni volani procedur pro xhomol21
GRANT EXECUTE ON procedura_zastoupeni_alkoholik TO xhomol21;
GRANT EXECUTE ON procedura_detaily_kontrola TO xhomol21;
GRANT EXECUTE ON napoveda TO xhomol21;

-- MATERIALIZOVANY POHLED:

DROP MATERIALIZED VIEW material_view_schuze;

CREATE MATERIALIZED VIEW LOG ON Schuze WITH PRIMARY KEY, ROWID(datum_cas_konani) INCLUDING NEW VALUES;

CREATE MATERIALIZED VIEW material_view_schuze
CACHE 
BUILD IMMEDIATE 
REFRESH FAST ON COMMIT 
ENABLE QUERY REWRITE 
AS SELECT S.datum_cas_konani, COUNT(S.datum_cas_konani) AS zastoupeni_stejneho_data_casu
FROM Schuze S
GROUP BY S.datum_cas_konani;

GRANT ALL ON material_view_schuze TO xhomol21;

-- TEST MAT. POHLEDU
-- SELECT dotaz proveden poprve
SELECT * FROM material_view_schuze;
-- vlozeny nove udaje do tabulky
INSERT INTO Schuze (datum_cas_konani) VALUES (TO_DATE('21/06/2019 14:00', 'DD/MM/YYYY HH24:MI'));
-- provedeni podruhe po vlozeni udaju - mat. pohled je nezmenen
SELECT * FROM material_view_schuze;
COMMIT;
-- provedeni SELECT dotazu potreti po vlozeni novych udaju - mat. pohled se zmeni, je nutne tedy pouzit prikaz COMMIT
SELECT * FROM material_view_schuze;





