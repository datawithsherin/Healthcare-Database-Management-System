-- HEALTHCARE DATABASE MANAGEMENT SYSTEM
-- COMPLETE SQL PROJECT

USE Healthcare;

SHOW TABLES;

--  1: DATA CHECK

SELECT 'Address' AS table_name, COUNT(*) AS total_rows FROM Address
UNION ALL
SELECT 'Disease', COUNT(*) FROM Disease
UNION ALL
SELECT 'Person', COUNT(*) FROM Person
UNION ALL
SELECT 'Patient', COUNT(*) FROM Patient
UNION ALL
SELECT 'InsuranceCompany', COUNT(*) FROM InsuranceCompany
UNION ALL
SELECT 'InsurancePlan', COUNT(*) FROM InsurancePlan
UNION ALL
SELECT 'Claim', COUNT(*) FROM Claim
UNION ALL
SELECT 'Treatment', COUNT(*) FROM Treatment
UNION ALL
SELECT 'Pharmacy', COUNT(*) FROM Pharmacy
UNION ALL
SELECT 'Prescription', COUNT(*) FROM Prescription
UNION ALL
SELECT 'Medicine', COUNT(*) FROM Medicine
UNION ALL
SELECT 'Keep', COUNT(*) FROM Keep
UNION ALL
SELECT 'Contain', COUNT(*) FROM Contain;

-- 2: CREATE INDEXES

-- CHECK EXISTING INDEXES FIRST

SHOW INDEX FROM Pharmacy;
SHOW INDEX FROM Treatment;
SHOW INDEX FROM Prescription;
SHOW INDEX FROM Claim;

-- CREATE ONLY THE INDEXES THAT DO NOT ALREADY EXIST

CREATE INDEX idx_pharmacy_address
ON Pharmacy(addressID);

CREATE INDEX idx_treat_patient
ON Treatment(patientID);

CREATE INDEX idx_treat_disease
ON Treatment(diseaseID);

CREATE INDEX idx_treat_claim
ON Treatment(claimID);

CREATE INDEX idx_presc_pharmacy
ON Prescription(pharmacyID);

CREATE INDEX idx_claim_uin
ON Claim(uin);

-- CHECK EXISTING INDEXES

SHOW INDEX FROM Pharmacy;
SHOW INDEX FROM Treatment;
SHOW INDEX FROM Prescription;
SHOW INDEX FROM Claim;



-- PROBLEM 1:
-- FIND TOP 3 CITIES WITH LOWEST
-- PHARMACY-TO-PRESCRIPTION RATIO
-- ONLY CITIES WITH MORE THAN 100 PRESCRIPTIONS
SELECT
    a.city,
    COUNT(DISTINCT ph.pharmacyID) AS pharmacies,
    COUNT(DISTINCT pr.prescriptionID) AS prescriptions,
    ROUND(
        COUNT(DISTINCT ph.pharmacyID) /
        COUNT(DISTINCT pr.prescriptionID), 4
    ) AS ratio
FROM Pharmacy ph
JOIN Address a
    ON ph.addressID = a.addressID
LEFT JOIN Prescription pr
    ON ph.pharmacyID = pr.pharmacyID
GROUP BY a.city
HAVING COUNT(DISTINCT pr.prescriptionID) > 100
ORDER BY ratio ASC
LIMIT 3;

-- PROBLEM 2:
-- FIND THE DISEASE WITH MAXIMUM NUMBER OF
-- TREATED PATIENTS IN EACH ALABAMA CITY

WITH city_disease AS (
    SELECT
        a.city,
        d.diseaseID,
        d.diseaseName,
        COUNT(DISTINCT t.patientID) AS total_patients
    FROM Treatment t
    JOIN Patient pt
        ON t.patientID = pt.patientID
    JOIN Person p
        ON pt.patientID = p.personID
    JOIN Address a
        ON p.addressID = a.addressID
    JOIN Disease d
        ON t.diseaseID = d.diseaseID
    WHERE a.state = 'AL'
    GROUP BY
        a.city,
        d.diseaseID,
        d.diseaseName
),
ranked_disease AS (
    SELECT
        city,
        diseaseName,
        total_patients,
        RANK() OVER (
            PARTITION BY city
            ORDER BY total_patients DESC
        ) AS disease_rank
    FROM city_disease
)
SELECT
    city,
    diseaseName,
    total_patients
FROM ranked_disease
WHERE disease_rank = 1
ORDER BY city;
-- PROBLEM 3:
-- FIND MOST AND LEAST CLAIMED INSURANCE PLANS
-- FOR EACH DISEASE

WITH plan_count AS (
    SELECT
        d.diseaseID,
        d.diseaseName,
        ip.uin,
        ip.planName,
        COUNT(DISTINCT c.claimID) AS total_claims
    FROM Treatment t
    JOIN Disease d
        ON t.diseaseID = d.diseaseID
    JOIN Claim c
        ON t.claimID = c.claimID
    JOIN InsurancePlan ip
        ON c.uin = ip.uin
    GROUP BY
        d.diseaseID,
        d.diseaseName,
        ip.uin,
        ip.planName
),
ranked AS (
    SELECT
        diseaseID,
        diseaseName,
        uin,
        planName,
        total_claims,
        RANK() OVER (
            PARTITION BY diseaseID
            ORDER BY total_claims DESC
        ) AS most_rank,
        RANK() OVER (
            PARTITION BY diseaseID
            ORDER BY total_claims ASC
        ) AS least_rank
    FROM plan_count
)

SELECT
    diseaseName,
    planName,
    total_claims,
    'Most Claimed' AS result
FROM ranked
WHERE most_rank = 1

UNION ALL

SELECT
    diseaseName,
    planName,
    total_claims,
    'Least Claimed' AS result
FROM ranked
WHERE least_rank = 1

ORDER BY diseaseName, result;

-- PROBLEM 4:
-- FIND HOUSEHOLDS WITH MORE THAN ONE PATIENT
-- HAVING THE SAME DISEASE
SELECT
    diseaseName,
    COUNT(*) AS total_households
FROM (
    SELECT
        d.diseaseID,
        d.diseaseName,
        p.addressID
    FROM Treatment t
    JOIN Patient pt
        ON t.patientID = pt.patientID
    JOIN Person p
        ON pt.patientID = p.personID
    JOIN Disease d
        ON t.diseaseID = d.diseaseID
    GROUP BY
        d.diseaseID,
        d.diseaseName,
        p.addressID
    HAVING COUNT(DISTINCT t.patientID) > 1
) AS household
GROUP BY
    diseaseID,
    diseaseName
ORDER BY total_households DESC;
-- PROBLEM 5:
-- STATE-WISE TREATMENT-TO-CLAIM RATIO
-- FINANCIAL YEAR:
-- 1 APRIL 2021 TO 31 MARCH 2022

SELECT
    a.state,
    COUNT(DISTINCT t.treatmentID) AS total_treatments,
    COUNT(DISTINCT t.claimID) AS total_claims,
    ROUND(
        COUNT(DISTINCT t.treatmentID) /
        NULLIF(COUNT(DISTINCT t.claimID), 0), 2
    ) AS ratio
FROM Treatment t
JOIN Patient pt
    ON t.patientID = pt.patientID
JOIN Person p
    ON pt.patientID = p.personID
JOIN Address a
    ON p.addressID = a.addressID
WHERE t.date >= '2021-04-01'
  AND t.date < '2022-04-01'
GROUP BY a.state
ORDER BY ratio DESC;
-- END 




