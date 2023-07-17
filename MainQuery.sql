--SELECT * FROM ..CovidDeaths
--ORDER BY 3 , 4 

--SELECT * FROM ..CovidVaccinations
--ORDER BY 3 , 4 

SELECT Location, date, population, total_cases, new_cases, total_Deaths
FROM PortfolioProject..CovidDeaths
where continent is not null
--and Location = 'Egypt'
ORDER BY 1,2

--Total cases Vs Total Deaths & Death Percentage
--The Percentage shows likelihood the chance of dying when u counter covid in your country

SELECT Location AS country, SUM(cast(new_cases as int)) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths, 
  CASE WHEN SUM(cast(new_cases as int)) = 0 THEN NULL ELSE (SUM(new_deaths) / SUM(cast(new_cases as int))) * 100 END AS death_percentage
FROM PortfolioProject..CovidDeaths
where continent is not null
--and location = 'Egypt'
GROUP BY Location
ORDER BY country

-- DAY BY DAY Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases, total_deaths, (CAST(total_deaths as float)/CAST(total_cases as float))*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
and location = 'Egypt'
order by 1,2

--Total Population to Total Cases
--To show how much percentage of the Infection_Rate of population

SELECT Location AS country,population , SUM(cast(new_cases as int)) AS total_cases,
  CASE WHEN SUM(cast(new_cases as int)) = 0 THEN NULL ELSE ( SUM(cast(new_cases as int)) / population) * 100 END AS Infection_Rate
FROM PortfolioProject..CovidDeaths
where continent is not null
--and location = 'Egypt'
GROUP BY Location,population
ORDER BY country

--Hight Infection_Rate According to Population
SELECT Location AS country,population ,SUM(cast(new_cases as int)) AS total_cases,
  CASE WHEN SUM(cast(new_cases as int)) = 0 THEN NULL ELSE ( SUM(cast(new_cases as int)) / population) * 100 END AS Infection_Rate
FROM PortfolioProject..CovidDeaths
where continent is not null
GROUP BY Location,population
ORDER BY Infection_Rate DESC

--Generally Higest Total Cases
SELECT Location AS Country, SUM(cast(New_cases as int)) AS Total_Cases
FROM CovidDeaths
--Subquery to unselect the global world and continents
WHERE Location NOT IN (
  SELECT TOP 7 Location
  FROM CovidDeaths
  GROUP BY Location
  ORDER BY SUM(cast(New_cases as int)) DESC
)
and continent is not null
GROUP BY Location
ORDER BY Total_Cases DESC

--Generally Higest Total Deaths
SELECT Location AS Country, SUM(cast(new_deaths as int)) AS Total_Deaths
FROM CovidDeaths
--Subquery to unselect the global world and continents
WHERE Location NOT IN (
  SELECT TOP 9 Location
  FROM CovidDeaths
  GROUP BY Location
  ORDER BY SUM(cast(new_deaths as int)) DESC
)
and continent is not null
GROUP BY Location
ORDER BY Total_Deaths DESC


-- DAY BY DAY Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From PortfolioProject..CovidDeaths
where continent is not null
--and location like 'Egypt'
order by 1,2


SELECT Location, Max(cast(population as bigint)) AS Population, Max(cast(total_cases as bigint)) AS Total_Cases, Max(cast(total_deaths as bigint)) AS Total_Deaths
FROM PortfolioProject..CovidDeaths
where continent is null
GROUP BY location
ORDER BY 1


--WORLD NUMBERS

SELECT Location, Max(cast(population as bigint)) AS Population, Max(cast(total_cases as bigint)) AS Total_Cases, Max(cast(total_deaths as bigint)) AS Total_Deaths
FROM PortfolioProject..CovidDeaths
where continent is null
and location ='World'
GROUP BY location


 --Total population vs Total_Vaccinations

  SELECT dea.Location,dea.population,dea.date,vac.new_vaccinations,
  SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) AS Total_Vaccinations
  from CovidDeaths dea
  join CovidVaccinations vac
  on dea.location =vac.location 
  and dea.date = vac.date
  where dea.continent is not null
  order by 1,2

  --Total population vaccinated percentage
  --USING CTE

  WITH VacPercentage  (Location,population,date,new_vaccinations,Total_Vaccinations) 
  AS
  (
  SELECT dea.Location,dea.population,dea.date,vac.new_vaccinations,
  SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location, dea.date) AS Total_Vaccinations
  from CovidDeaths dea
  join CovidVaccinations vac
  on dea.location =vac.location 
  and dea.date = vac.date
  where dea.continent is not null
)
Select *, (Total_Vaccinations/population)*100 AS Fully_Vaccinations_Percentage
FROM VacPercentage


--Population to Fully Vaccinated people percentage, new vaccinations,total vaccinations

SELECT dea.location, dea.population, dea.date, vac.new_vaccinations_smoothed, vac.total_vaccinations AS total_vaccinations_used,people_fully_vaccinated,(vac.people_fully_vaccinated/dea.population)*100 AS Fully_Vaccinations_Percentage
FROM CovidDeaths dea
Join CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
	where dea.continent is not null
	--and dea.location like 'EGyp%'
	Order by 1,3

--highest countries of people fully vaccinated

SELECT 
  location, 
  MAX(cast(people_fully_vaccinated as bigint)) AS people_fully_vaccinated  
FROM 
  CovidVaccinations
  where continent is not null
GROUP BY 
  location
  order by people_fully_vaccinated  DESC 

--Continent Pepole fully vaccinations

SELECT 
  location, 
  MAX(cast(people_fully_vaccinated as bigint)) AS people_fully_vaccinated 
FROM 
  CovidVaccinations
  where continent is null
GROUP BY 
  location
  order by people_fully_vaccinated DESC 


--first day each country started to give vaccinations
SELECT 
  dea.location, 
  MIN(dea.date) AS first_vaccination_date
FROM 
  CovidDeaths dea
  JOIN CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
  dea.continent IS NOT NULL AND vac.new_people_vaccinated_smoothed IS NOT NULL
GROUP BY 
  dea.location
  order by first_vaccination_date 


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 










