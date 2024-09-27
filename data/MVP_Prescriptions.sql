--Multiple drugs with the same name is due to different dosage details in the generic_name column.

SELECT *
FROM prescription;

--1a) Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims. <1881634483>
SELECT npi, SUM(total_claim_count)
FROM prescription
GROUP BY npi
ORDER BY SUM(total_claim_count) DESC;

--1b) Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name, 
--specialty_description, and the total number of claims.

SELECT pbr.nppes_provider_first_name, pbr.nppes_provider_last_org_name, pbr.specialty_description, SUM(rx.total_claim_count)
FROM prescription AS rx
INNER JOIN prescriber AS pbr
	USING(npi)
GROUP BY pbr.nppes_provider_first_name, pbr.nppes_provider_last_org_name, pbr.specialty_description
ORDER BY SUM(total_claim_count) DESC;

--2a) Which specialty had the most total number of claims (totaled over all drugs)? <Family Practice>

SELECT pbr.specialty_description, SUM(rx.total_claim_count)
FROM prescription AS rx
INNER JOIN prescriber AS pbr
	USING(npi)
GROUP BY pbr.specialty_description
ORDER BY SUM(total_claim_count) DESC;

--2b) Which specialty had the most total number of claims for opioids? <Nurse Practitioner>

SELECT pbr.specialty_description, SUM(rx.total_claim_count)
FROM prescription AS rx
INNER JOIN prescriber AS pbr
	USING(npi)
INNER JOIN drug AS d
	USING(drug_name)
WHERE d.opioid_drug_flag = 'Y'
GROUP BY pbr.specialty_description
ORDER BY SUM(total_claim_count) DESC;

--2c) **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table? <Yes, 15 of them>

SELECT pbr.specialty_description, SUM(rx.total_claim_count)
FROM prescription AS rx
FULL JOIN prescriber AS pbr
	USING(npi)
GROUP BY pbr.specialty_description
HAVING SUM(rx.total_claim_count) IS NULL;

--2d) **Difficult Bonus:** *Do not attempt until you have solved all other problems!** 
--For each specialty, report the percentage of total claims by that specialty which are for opioids. 
--Which specialties have a high percentage of opioids?
--<Case Manager/Care Coordinator 72%>

WITH total_percent_of_claims AS 
	(SELECT pbr.specialty_description, SUM(rx.total_claim_count) AS total_percent
	FROM prescriber AS pbr
		INNER JOIN prescription AS rx
		USING(npi)
		INNER JOIN drug AS d
		USING(drug_name)
	WHERE opioid_drug_flag = 'Y'
	GROUP BY specialty_description)
SELECT pbr.specialty_description, ROUND((total_percent / SUM(total_claim_count)*100)) AS percentage
FROM prescription
	INNER JOIN prescriber AS pbr
		USING(npi)
	INNER JOIN total_percent_of_claims
		USING(specialty_description)
GROUP BY pbr.specialty_description, total_percent
ORDER BY percentage DESC;

--3a) Which drug (generic_name) had the highest total drug cost? <INSULIN GLARGINE,HUM.REC.ANLOG>

SELECT d.generic_name, SUM(rx.total_drug_cost)::MONEY
FROM drug AS d
INNER JOIN prescription AS rx
USING(drug_name)
GROUP BY d.generic_name
ORDER BY SUM(total_drug_cost) DESC;

--3b) Which drug (generic_name) has the hightest total cost per day? 
--**Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
--<C1 ESTERASE INHIBITOR at 3495.22>

SELECT d.generic_name, CAST((SUM(rx.total_drug_cost)) / (SUM(rx.total_day_supply)) AS MONEY) AS avg_cost_per_day
FROM drug AS d
INNER JOIN prescription AS rx
USING(drug_name)
GROUP BY d.generic_name
ORDER BY avg_cost_per_day DESC;

--4a) For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' 
--for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', 
--and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. 
--See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/

SELECT DISTINCT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type
FROM drug;

--4b) Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. 
--Hint: Format the total costs as MONEY for easier comparison. <OPIOID>

SELECT
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither' END AS drug_type,
	sum(rx.total_drug_cost::MONEY) AS most_spent
FROM drug AS d
	INNER JOIN prescription AS rx
	USING(drug_name)
GROUP BY drug_type;

--5a) How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee. <10>

SELECT COUNT(DISTINCT(CBSA))
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--5b) Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population. <Nashville-Davidson-Murfreesboro-Franklin is largest, 
--Morristown is smallest>

SELECT c.cbsaname, SUM(population)
FROM cbsa AS c
INNER JOIN population AS p
USING(fipscounty)
GROUP BY c.cbsaname
ORDER BY sum DESC;

--5c) What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT f.county, p.population
FROM cbsa AS c
	RIGHT JOIN population AS p
		USING(fipscounty)
	INNER JOIN fips_county AS f
		USING(fipscounty)
WHERE cbsa IS NULL
ORDER BY p.population DESC;

--6a) Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >= 3000 
ORDER BY total_claim_count DESC;

--6b) For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

SELECT rx.drug_name, rx.total_claim_count, d.opioid_drug_flag
FROM prescription AS rx
INNER JOIN drug AS d
USING(drug_name)
WHERE total_claim_count >= 3000 
ORDER BY total_claim_count DESC;

--6c) Add another column to your answer from the previous part which gives the prescriber first and last name associated with each row.

SELECT rx.drug_name, rx.total_claim_count, d.opioid_drug_flag, nppes_provider_last_org_name, nppes_provider_first_name
FROM prescription AS rx
INNER JOIN drug AS d
USING(drug_name)
INNER JOIN prescriber AS pbr
USING(npi)
WHERE total_claim_count >= 3000 
ORDER BY total_claim_count DESC;

--7) The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.

SELECT npi, nppes_provider_last_org_name, nppes_provider_first_name, specialty_description
FROM prescriber
WHERE nppes_provider_city = 'NASHVILLE';

--7a) First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management)
--in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). 
--**Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

SELECT npi, drug_name
FROM prescriber
CROSS JOIN drug
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y';

--7b) Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT pbr.npi, d.drug_name, total_claim_count
FROM prescriber AS pbr
CROSS JOIN drug AS d
FULL JOIN prescription AS rx
	USING(npi, drug_name) 
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC NULLS LAST;

--7c) Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.

SELECT pbr.npi, d.drug_name, COALESCE(total_claim_count,0) AS total
FROM prescriber AS pbr
CROSS JOIN drug AS d
FULL JOIN prescription AS rx
	USING(npi, drug_name) 
WHERE specialty_description = 'Pain Management'
	AND nppes_provider_city = 'NASHVILLE'
	AND opioid_drug_flag = 'Y'
ORDER BY total DESC;