/* 

Updating the old queries for tableau

*/

-- Initial query check

--SELECT date,location, new_cases, total_cases , total_deaths
--FROM Covid_deaths$
--ORDER BY 2,1;



-- Total cases and deaths by continent

SELECT continent as Continent, MAX(CAST(total_deaths as int)) as TotalDeathCount, MAX(total_cases) as TotalCaseCount
FROM Covid_deaths$ 
WHERE continent IS NOT NULL
GROUP BY continent
--ORDER BY Tot_Death_Count DESC;



-- Showing Date and Location wise # of cases and deaths.

SELECT location, population, date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected,
MAX(CAST(total_deaths AS INT)) as HighestDeathCount, ROUND(MAX(CAST(total_deaths AS INT))/population*100,3) as PercentPopulationDeath
FROM Covid_deaths$
GROUP BY location, population, date
--order by PercentPopulationInfected desc



--Shows percentage of population affected and likelihood of dying if you contract covid by country.

SELECT location as Loc, population as Pop, MAX(total_cases) Tot_cases, MAX(CAST(total_deaths AS INT)) Tot_deaths, 
ROUND(MAX(total_cases)/MAX(population)*100,3)as PopPercAffected, 
ROUND(MAX(CAST(total_deaths AS INT))/MAX(total_cases)*100,3) DeathPerc
FROM Covid_deaths$
WHERE continent IS NOT NULL
GROUP BY location, population 
--ORDER BY Tot_deaths desc;



-- Date wise covid case rise and deaths in the world.

SELECT date Date, SUM(new_cases) Cases, SUM(CAST(new_deaths AS INT)) Deaths, 
ROUND(SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100,3) DeathPerc
FROM Covid_deaths$
WHERE continent IS NOT NULL
GROUP BY Date
ORDER BY Date;



-- Looking at total population vs vaccinations

SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingCountVaccinations
FROM Covid_deaths$ cd 
JOIN Covid_vaccinations$ cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY 1,2,3;



--Using CTE to be able to use the column header we declared in calculations

WITH PopVSVac (Continent, Location, Date, Population, NewVax, RollingCountVaccinations)
AS 
(SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingCountVaccinations
FROM Covid_deaths$ cd 
JOIN Covid_vaccinations$ cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 1,2,3;
)

SELECT *, ROUND((RollingCountVaccinations/Population)*100,6) as VaxPerc FROM PopVSVac
ORDER BY 1,2,3;



--Using TEMP table to be able to use the column header we declared in calculations

--DROP TABLE IF EXISTS #PercPopulationVaxxed
CREATE TABLE #PercPopulationVaxxed
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
NewVaccinations numeric,
RollingCountVaccinations numeric
)

INSERT INTO #PercPopulationVaxxed
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingCountVaccinations
FROM Covid_deaths$ cd 
JOIN Covid_vaccinations$ cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
--ORDER BY 1,2,3;

SELECT *, ROUND((RollingCountVaccinations/Population)*100,6) as VaxPerc FROM #PercPopulationVaxxed
ORDER BY 1,2,3;



-- Creating view for obtaining the data later for viz

--DROP VIEW IF EXISTS PercentPopulationVaccinated_View
CREATE VIEW PercentPopulationVaccinated_View as 
SELECT cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
SUM(CONVERT(BIGINT, cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) as RollingCountVaccinations
FROM Covid_deaths$ cd 
JOIN Covid_vaccinations$ cv
ON cd.location = cv.location
AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
----ORDER BY 1,2,3;

SELECT * 
FROM PercentPopulationVaccinated_View

