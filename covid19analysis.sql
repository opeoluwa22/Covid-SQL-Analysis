-- COVID-19 DATA ANALYSIS
-- Database: SQLite (DB Browser)

-- 1. BASIC DATA EXPLORATION
SELECT *
FROM CovidDeaths1
WHERE continent IS NOT NULL
ORDER BY 3;

-- Key columns for analysis
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths1
ORDER BY 1, 2;

-- 2. TOTAL CASES VS TOTAL DEATHS (UK Focus)
SELECT 
    location, 
    date, 
    total_cases, 
    new_cases, 
    total_deaths, 
    (total_deaths * 1.0 / total_cases) * 100 AS DeathPercent
FROM CovidDeaths1
WHERE location LIKE '%kingdom%'
ORDER BY 1;

-- 3. TOTAL CASES VS POPULATION (UK Focus)
SELECT 
    location, 
    date, 
    total_cases, 
    population, 
    (total_cases * 1.0 / population) * 100 AS PopulationPercent
FROM CovidDeaths1
WHERE location LIKE '%kingdom%'
ORDER BY 1;

-- 4. HIGHEST INFECTION RATE PER COUNTRY
SELECT 
    location, 
    population, 
    MAX(total_cases) AS HighestInfectionCount, 
    MAX((total_cases * 1.0 / population)) * 100 AS PopulationPercent
FROM CovidDeaths1
GROUP BY location, population
ORDER BY PopulationPercent DESC;

-- 5. HIGHEST DEATH COUNT PER COUNTRY
SELECT 
    location, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths1
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- 6. HIGHEST DEATH COUNT PER CONTINENT
SELECT 
    continent, 
    MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths1
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- 7. GLOBAL NUMBERS
SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(CAST(new_deaths AS INT)) AS total_deaths, 
    SUM(CAST(new_deaths AS INT)) / SUM(new_cases * 1.0) * 100 AS DeathPercentage
FROM CovidDeaths1
WHERE continent IS NOT NULL;

-- 8. TOTAL POPULATION VS VACCINATIONS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY substr(dea.date, 7, 4) || '-' || 
                 substr(dea.date, 4, 2) || '-' || 
                 substr(dea.date, 1, 2)
    ) AS RollingPeopleVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, substr(dea.date, 7, 4) || '-' || 
                           substr(dea.date, 4, 2) || '-' || 
                           substr(dea.date, 1, 2);

-- 9. CTE: VACCINATION PERCENTAGE PER COUNTRY
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
    SELECT 
        dea.continent, 
        dea.location, 
        dea.date, 
        dea.population, 
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (
            PARTITION BY dea.location 
            ORDER BY substr(dea.date, 7, 4) || '-' || 
                     substr(dea.date, 4, 2) || '-' || 
                     substr(dea.date, 1, 2)
        ) AS RollingPeopleVaccinated
    FROM CovidDeaths1 dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT 
    *, 
    (RollingPeopleVaccinated * 1.0 / Population) * 100 AS PercentPeopleVaccinated
FROM PopvsVac;

-- 10. TEMP TABLE: VACCINATION PERCENTAGE
DROP TABLE IF EXISTS TempPercentVaccinated;

-- Create temp table
CREATE TEMP TABLE TempPercentVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Query temp table
SELECT 
    *, 
    (RollingPeopleVaccinated * 1.0 / Population) * 100 AS PercentVaccinated
FROM TempPercentVaccinated
ORDER BY Location, Date;

-- 11. VIEW: PERCENT POPULATION VACCINATED

-- Drop view if exists
DROP VIEW IF EXISTS ViewPercentVaccinated;

-- Create view with percentage
CREATE VIEW ViewPercentVaccinated AS
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) AS RollingPeopleVaccinated,
    (SUM(CAST(vac.new_vaccinations AS INT)) OVER (
        PARTITION BY dea.location 
        ORDER BY dea.date
    ) * 1.0 / dea.population) * 100 AS PercentVaccinated
FROM CovidDeaths1 dea
JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

-- Query the view
SELECT * 
FROM ViewPercentVaccinated 
ORDER BY location, date;

-- Top 10 countries by vaccination rate
SELECT 
    location,
    MAX(PercentVaccinated) AS HighestVaccinationRate
FROM ViewPercentVaccinated
GROUP BY location
ORDER BY HighestVaccinationRate DESC
LIMIT 10;

-- 12. UTILITY: CHECK VIEWS AND TABLES
-- List all views
SELECT name FROM sqlite_master WHERE type='view';

-- List all temp tables
SELECT name FROM sqlite_temp_master WHERE type='table';

-- Check view schema
SELECT sql FROM sqlite_master WHERE type='view' AND name='ViewPercentVaccinated';

-- Query the view
SELECT * 
FROM ViewPercentVaccinated 
ORDER BY location, date;