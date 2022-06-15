SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT * 
--PortfolioProject..CovidVaccinations
--ORDER BY 3,4
-- Select the data we are going to be using

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY 1,2

-- Looking at the total cases vs total deaths
-- Shows the likelihood of dying if you contract covid in USA

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at the total cases vs population
-- Shows percentage of population got covid

SELECT Location, date, population, total_cases, (total_cases/population)*100 as infected_percentage
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
and continent is not null
ORDER BY 1,2

-- What country has the highest infection rate

SELECT Location, population, MAX(total_cases) as HighestInfectionCount, (MAX(total_cases/population))*100 as infected_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location, population
ORDER BY infected_percentage desc -- these numbers represent the columns

-- Showing the countries with the highest death count per population

SELECT Location, MAX(total_deaths) AS WrongTotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY WrongTotalDeathCount desc

-- This doesn't order correctly and so we need to cast the MAX as an integer

SELECT Location, MAX(cast(total_deaths AS int)) AS ALLTotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY ALLTotalDeathCount desc 

-- This includes the locations: world, eu, na, sa, asia which we don't want. To do this we exclude data with continent=null. We add this to every script.

SELECT Location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc 

-- Investigate by continent

-- Showing the continent with the highest death count

SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc 

-- Global Investigation

SELECT date, SUM(new_cases), SUM(new_deaths)--, total_deaths, (total_deaths/total_cases)*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Operand data type nvarchar is invalid for sum operator. --> We need to cast as integer again ( could also use: CONVERT(int, xyz))

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(New_deaths as int))/SUM(new_cases)*100 AS death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Joining the 2 excel databases on location column and date column

SELECT *
FROM PortfolioProject..CovidDeaths dea        -- These are alias
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date

-- Looking at total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject..CovidDeaths dea        -- These are alias so we don't have to write the full db name each time
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

-- Rolling count of new vaccinations per day

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as new_vaccinated, (new_vaccinated/population)*100 -- we want it to count until a new location and then start again
FROM PortfolioProject..CovidDeaths dea        -- These are alias so we don't have to write the full db name each time
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
order by 2,3

-- Invalid column name 'new_vaccinated'. Therefore we need to create a temporary table OR use a CTE

-- CTE

WITH PopvsVac (continent, location, date, population, new_vaccinations, new_vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as new_vaccinated -- we want it to count until a new location and then start again
FROM PortfolioProject..CovidDeaths dea        -- These are alias so we don't have to write the full db name each time
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
)
SELECT *, (new_vaccinated/population)*100 as vaccination_percentage
FROM PopvsVac

-- Temporary table (same result as CTE just another method)

DROP TABLE IF exists #PercentPopulationVaccinated -- This avoids the following error: There is already an object named '#PercentPopulationVaccinated' in the database.
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location NVARCHAR(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
New_vaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as new_vaccinated -- we want it to count until a new location and then start again
FROM PortfolioProject..CovidDeaths dea        -- These are alias so we don't have to write the full db name each time
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

SELECT *, (new_vaccinated/population)*100 as vaccination_percentage
FROM #PercentPopulationVaccinated

-- Creating a view to store data (to look in tableau later)

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as new_vaccinated -- we want it to count until a new location and then start again
FROM PortfolioProject..CovidDeaths dea        -- These are alias so we don't have to write the full db name each time
JOIN PortfolioProject..CovidVaccinations vac  -- 
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null

-- Saving this into Github

