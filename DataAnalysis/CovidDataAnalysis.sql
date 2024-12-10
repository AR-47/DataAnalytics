-- Selecting all data from the CovidDeaths table where continent is not NULL and ordering by columns 3 and 4
SELECT *
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Selecting relevant columns for analysis and ordering by continent and location
SELECT continent, location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Calculating the likelihood of dying from COVID in a country by computing the death percentage (total deaths / total cases * 100)
SELECT continent, location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Analyzing what percentage of the population got infected by COVID (total cases / population * 100)
SELECT continent, location, date, population, total_cases, (total_cases / population) * 100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths 
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Identifying countries with the highest infection rate compared to population (total cases / population * 100)
SELECT continent, location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS PercentagePopulationInfected
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, population, location
ORDER BY PercentagePopulationInfected DESC


-- Identifying countries with the highest death count per population (total deaths per population)
SELECT continent, location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCounts
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent,population, location
ORDER BY TotalDeathCounts DESC


-- Aggregating death counts by continent
SELECT continent, MAX(CAST(total_deaths AS INT)) AS TotalDeathCounts
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCounts DESC


-- Global summary of new cases, new deaths, and death percentage (total new deaths / total new cases * 100)
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths, SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2


-- Now analyzing the vaccination dataset:
-- Comparing population and new vaccinations across countries

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,SUM(CAST(vac.new_vaccinations AS INT)) 
OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3


-- Using a Common Table Expression (CTE) to calculate population vs vaccination data

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) 
AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
-- Selecting the vaccination percentage for each country by calculating (RollingPeopleVaccinated / Population) * 100
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM PopvsVac


-- Using temporary tables to store vaccination data and calculate percentage

-- Dropping the temp table if it already exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated 

-- Creating a new temp table to store vaccination-related data
CREATE TABLE #PercentPopulationVaccinated
(
Continent NVARCHAR(255),
Location NVARCHAR(255),
Date DATETIME,
Population NUMERIC,
New_Vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)

-- Inserting the calculated data into the temp table
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

-- Selecting the data from the temp table and calculating vaccination percentage
SELECT *, (RollingPeopleVaccinated / Population) * 100
FROM #PercentPopulationVaccinated


-- Creating a view for storing data related to population and vaccination for easy use in future queries

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date

-- Selecting data from the created view for further analysis or visualization
SELECT *
FROM PercentPopulationVaccinated
