CREATE DATABASE IF NOT EXISTS credit_risk_project;
USE credit_risk_project;

#############################################################################################
#SIND ALLE ZEILEN DES GESAMTEN DATENSATZES ENTHALTEN UND AUCH ALLE NULL-WERTE MIT ÜBERNOMMEN
#############################################################################################
SELECT
    COUNT(*) AS gesamt,
    SUM(person_emp_length IS NULL) AS fehlende_anstellungsdauer,
    SUM(loan_int_rate IS NULL) AS fehlender_zinssatz
FROM cr;

    
##########################################################################################################################################   
# WELCHE MERKMALE HÄNGEN MIT EINEM HÖHEREN KREDITAUSFALLRISIKO ZUSAMMEN UND WELCHE KUNDEN SOLLTEN STÄRKER ODER WENIGER ÜBERWACHT WERDEN ?
# HIERFÜR IST DIE SPALTE loan_status DAS WICHTIGSTE FELD.
##########################################################################################################################################

-- WIE VIELE KREDITE HABEN DEN LOAN_STATUS 0 BZW. 1?

SELECT loan_status, COUNT(loan_status) Anzahl
FROM cr
GROUP BY loan_status;

-- WIEVIEL PROZENT DER KREDITE SIND AUSGEFALLEN?

SELECT ROUND(AVG(loan_status) * 100, 2) AS 'Ausfallquote in %'
FROM cr;

-- WIE UNTERSCHEIDET SICH DIE AUSFALLQUOTE ZWISCHEN DEN EINZELNEN LOAN GRADES?

SELECT loan_grade, COUNT(loan_grade) Anzahl,
ROUND(AVG(loan_status) * 100,2) 'Ausfallquote in %'
FROM cr
GROUP BY loan_grade
ORDER BY loan_grade;

-- BESTEHT EIN ZUSAMMENHANG ZWISCHEN EINEM FRÜHEREN ZAHLUNGSAUSFALL
-- UND DEM AUSFALL DES AKTUELLEN KREDITS?

SELECT cb_person_default_on_file, COUNT(cb_person_default_on_file) Anzahl,
ROUND(AVG(loan_status) * 100,2) 'Zahlungsausfall in %'
FROM cr
GROUP BY cb_person_default_on_file;

-- WIE VERÄNDERT SICH DIE AUSFALLQUOTE IN ABHÄNGIGKEIT
-- VOM KREDITANTEIL AM EINKOMMEN?

SELECT 
CASE
WHEN loan_percent_income <= 0.10 THEN 'bis 10 %'
WHEN loan_percent_income <= 0.20 THEN 'bis 20 %'
WHEN loan_percent_income <= 0.30 THEN 'bis 30 %'
WHEN loan_percent_income <= 0.40 THEN 'bis 40 %'
ELSE 'über 40 %'
END Einkommensanteil ,
COUNT(*) Anzahl,
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
GROUP BY Einkommensanteil
ORDER BY Einkommensanteil, Anzahl;


-- WAS PASSIERT, WENN MEHRERE RISIKOMERKMALE
-- GLEICHZEITIG AUFTRETEN?

SELECT 
COUNT(*) AS Anzahl,
SUM(loan_status) AS Ausgefallen,
ROUND(AVG(loan_status) * 100, 2) AS 'Ausfallquote in %'
FROM cr
WHERE loan_grade IN ('D', 'E', 'F', 'G')
AND loan_percent_income > 0.30;

SELECT COUNT(*) Anzahl,
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_grade IN ('D', 'E', 'F', 'G') AND loan_percent_income > 0.30
AND cb_person_default_on_file IN ('Y');

-- WELCHE RISIKOKLASSE WEIST DIE HÖCHSTE AUSFALLQUOTE
-- IM DATENSATZ AUF UND WIE IST DIE REIHENFOLGE DES WEITEREN RANKINGS

SELECT loan_grade,
COUNT(*) AS Anzahl,
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %',
RANK() OVER(ORDER BY AVG(loan_status) DESC) Risikorang
FROM cr
GROUP BY loan_grade
ORDER BY Risikorang; 

-- UNTERSCHEIDEN SICH DIE AUSFALLQUOTEN JE NACH WOHN -UND EIGENTUMSSITUATION?

SELECT person_home_ownership,
COUNT(person_home_ownership),
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
GROUP BY person_home_ownership;


############################################################################
# AUFGABE 2 – KREDITVERGABE UND PREISGESTALTUNG
# PASSEN KREDITHÖHE UND ZINSSATZ ZUM TATSÄCHLICHEN RISIKO DER KREDITNEHMER?
############################################################################

-- UNTERSCHEIDET SICH DER ø ZINSSATZ ZWISCHEN KREDITEN, DIE AUSGEFALLEN SIND
-- UND KREDITEN, DIE NICHT AUSGEFALLEN SIND?

SELECT loan_status,
COUNT(*) Anzahl,
ROUND(AVG(loan_int_rate), 2) 'ø Zinssatz'
FROM cr
GROUP BY loan_status;

-- STEIGT DER ø ZINSSATZ MIT SCHLECHTER WERDENDEM LOAN_GRADE?

SELECT loan_grade,
COUNT(*) Anzahl,
ROUND(AVG(loan_int_rate), 2) 'ø Zinssatz'
FROM cr
GROUP BY loan_grade
ORDER BY loan_grade;

-- WIE ENTWICKELN SICH ZINSSATZ UND TATSÄCHLICHE
-- AUSFALLQUOTE INNERHALB DER EINZELNEN LOAN GRADES?

SELECT loan_grade,
ROUND(AVG(loan_int_rate),2) 'ø Zinssatz',
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
GROUP BY loan_grade
ORDER BY loan_grade;


-- STEIGT DIE AUSFALLQUOTE BEI HÖHEREN KREDITBETRÄGEN?

SELECT MAX(loan_amnt),
MIN(loan_amnt),
ROUND(AVG(loan_amnt), 2) FROM cr;

SELECT
CASE
WHEN loan_amnt <= 5000 THEN 'Kredit bis 5000 $'
WHEN loan_amnt <= 10000 THEN 'Kredit bis 10000 $'
WHEN loan_amnt <= 15000 THEN 'Kredit bis 15000 $'
WHEN loan_amnt <= 20000 THEN 'Kredit bis 20000 $'
ELSE 'Kredit über 20000 $'
END Kreditsumme,
COUNT(*),
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
GROUP BY Kreditsumme;

-- WIE HOCH IST DIE AUSFALLQUOTE BEI KREDITEN,
-- DIE DEN ø KREDITBETRAG ÜBERSTEIGEN?

SELECT
COUNT(*) Anzahl,
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_amnt > (SELECT AVG(loan_amnt)
FROM cr);

-- VERGIBT DIE BANK AUCH AN KREDITNEHMER MIT SCHLECHTEREM
-- LOAN GRADE KREDITE DIE ÜBER DER ø KREDITSUMME LIEGEN?

SELECT loan_grade, COUNT(*) Anzahl, 
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_grade IN ('D', 'E', 'F', 'G') 
AND loan_amnt > (SELECT AVG(loan_amnt)
FROM cr)
GROUP BY loan_grade;


-- WIE HOCH IST DIE AUSFALLQUOTE BEI KREDITEN,
-- DIE ÜBER DER DURCHSCHNITTLICHEN KREDITSUMME LIEGEN
-- UND GLEICHZEITIG MEHR ALS 30 % DES EINKOMMENS AUSMACHEN?

SELECT COUNT(*) Anzahl, 
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_amnt > (SELECT AVG(loan_amnt) FROM cr)
AND loan_percent_income > 0.30;

-- GEGENPROBE:
-- WIE HOCH IST DIE AUSFALLQUOTE BEI ÜBERDURCHSCHNITTLICHEN KREDITEN,
-- WENN DIE KREDITBELASTUNG HÖCHSTENS 30 % DES EINKOMMENS BETRÄGT?

SELECT COUNT(*) Anzahl, 
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_amnt > (SELECT AVG(loan_amnt) FROM cr)
AND loan_percent_income <= 0.30;

-- VIEW ZUM DIREKTEN VERGLEICH DER BEIDEN BELASTUNGSGRUPPEN

CREATE OR REPLACE VIEW kreditbelastung_vergleich AS
SELECT 'bis 30 %' Belastungsgruppe,
COUNT(*) Anzahl, 
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_amnt > (SELECT AVG(loan_amnt) FROM cr)
AND loan_percent_income <= 0.30
UNION ALL
SELECT 'über 30 %' Belastungsgruppe,
COUNT(*) Anzahl, 
ROUND(AVG(loan_status) * 100, 2) 'Ausfallquote in %'
FROM cr
WHERE loan_amnt > (SELECT AVG(loan_amnt) FROM cr)
AND loan_percent_income > 0.30;

SELECT * FROM kreditbelastung_vergleich;


##############################################
#REDUZIERTE,STANDARD,INTENSIVIERTE ÜBERWACHUNG
##############################################

SELECT 
COUNT(*) AS Anzahl,
ROUND(AVG(loan_status) * 100, 3) AS Ausfallquote
FROM cr
WHERE loan_grade IN ('A', 'B');

SELECT 
COUNT(*) AS Anzahl_Kredite,
ROUND(AVG(loan_status) * 100, 2) AS Ausfallquote
FROM cr
WHERE loan_percent_income > 0.20
AND loan_percent_income <= 0.30;

SELECT 
COUNT(*) AS Anzahl_Kredite,
ROUND(AVG(loan_status) * 100, 2) AS Ausfallquote
FROM cr
WHERE loan_grade IN ('D', 'E', 'F', 'G')
AND loan_percent_income > 0.30;
