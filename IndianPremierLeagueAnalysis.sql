
#looking at Player batting avaerage over the years 

SELECT Year, Player_Name, Batting_Average as HighestBattingAverage
FROM PortfolioProject2.cricket_batting cb1
WHERE Batting_Average = (
    SELECT MAX(Batting_Average)
    FROM PortfolioProject2.cricket_batting cb2
    WHERE cb1.Year = cb2.Year
)
ORDER BY HighestBattingAverage DESC;

#looking at Strike rate of players over the years
SELECT Year, Player_Name,Batting_Strike_Rate as HighestBattingSR
FROM PortfolioProject2.cricket_batting cb1
WHERE Batting_Strike_Rate = (
    SELECT MAX(Batting_Strike_Rate)
    FROM PortfolioProject2.cricket_batting cb2
    WHERE cb1.Year = cb2.Year
)
ORDER BY HighestBattingSR DESC;

#looking at average batting strikerate and average runs scored
SELECT Player_Name, Count(*) as TotalSeasonsPlayed, SUM(Matches_Batted) as TotalMatchesPlayed, round(avg(Batting_Average),2) as AverageBattingAverage, round(avg(Batting_Strike_Rate),2) as AverageStrikeRate From PortfolioProject2.cricket_batting
Group by Player_Name
order by AverageBattingAverage desc;

#Looking at Player's Boundary Conversion againist number of balls faced
Select  Player_Name, Sum(Balls_Faced) as TotalBallFaced , Sum(Fours) as TotalFoursConverted , (Sum(Fours) / Sum(Balls_Faced))*100 as BoundaryPercentage From PortfolioProject2.cricket_batting
Group by Player_Name
order by BoundaryPercentage desc;

#Looking at Player's Six Conversion againist number of balls faced
Select  Player_Name, Sum(Balls_Faced) as TotalBallFaced , Sum(Sixes) as TotalSixesConverted , (Sum(Sixes) / Sum(Balls_Faced))*100 as SixesPercentage From PortfolioProject2.cricket_batting
Group by Player_Name
order by SixesPercentage  desc;

#looking at Total Half Centuries by batters
Select Player_Name,  Sum(Half_Centuries)as TotalHalfCenturies from PortfolioProject2.cricket_batting
Group by Player_Name
order by TotalHalfCenturies desc;

#looking at Total Half Centuries by batters
Select Player_Name,  Sum(Centuries)as TotalCenturies from PortfolioProject2.cricket_batting
Group by Player_Name
order by TotalCenturies desc;

# looking at year over year performance changes - Performance Variation Analysis
with yearoveryear as (
  select  
    Player_Name, Year, 
    Batting_Average, 
    LAG(Batting_Average) OVER(PARTITION BY Player_Name ORDER BY Year) as Prev_Year_Avg,
	Batting_Strike_Rate,
    LAG(Batting_Strike_Rate) OVER(PARTITION BY Player_Name ORDER BY Year) as Prev_Year_SR
  from PortfolioProject2.cricket_batting
  Where Batting_Average > 0 AND Batting_Strike_Rate > 0
)
select 
  Player_Name, Year, 
  Batting_Average,Prev_Year_Avg,
  ROUND(((Batting_Average - Prev_Year_Avg) / Prev_Year_Avg) * 100,2) AS Avg_Change_Percentage,
  Batting_Strike_Rate, Prev_Year_SR,
  ROUND(((Batting_Strike_Rate - Prev_Year_SR) / Prev_Year_SR) * 100, 2) AS SR_Change_Percentage
from yearoveryear
where Prev_Year_Avg is not null
order by Player_Name, Year;

#Looking at Performance Consistency Metrics 
with playerstats as (
  Select 
   Player_Name, Count(*) as Seasons_Played, 
   Round(Avg(Batting_Average), 2) as Mean_Average,
   Round(Stddev(Batting_Average), 2) as Std_Dev_Average,
   Round(Avg(Batting_Strike_Rate), 2) as Mean_Strike_Rate,
   Round(Stddev(Batting_Strike_Rate), 2) as Std_Dev_Strike_Rate
  From PortfolioProject2.cricket_batting
  WHERE Batting_Average > 0 AND Batting_Strike_Rate > 0
  Group by Player_Name
  HAVING COUNT(*) >= 5 
)
Select 
  Player_Name, Seasons_Played, 
  Mean_Average,Std_Dev_Average,
  Round((Std_Dev_Average/Mean_Average)*100, 2) as Avg_Coefficient_of_Variation,
  Mean_Strike_Rate,Std_Dev_Strike_Rate,
  Round((Std_Dev_Strike_Rate/ Mean_Strike_Rate)*100, 2) as SR_Coefficient_of_Variation
From playerstats
ORDER BY Avg_Coefficient_of_Variation;
  
  
Show columns from PortfolioProject2.cricket_batting; # Checking Data Types
Show columns from PortfolioProject2.cricket_bowling; #Checking Data Types

#Looking into Peak Performance Year of Each Player
With  TotalRunsScoredYear as (
   Select Player_Name,Year,Runs_Scored, Dense_Rank()  Over (Partition by Player_Name Order by Runs_Scored desc) as PeakRank
   From PortfolioProject2.cricket_batting Bat
   where Runs_Scored>0
)
Select Player_Name, Year as Peak_Year, Runs_Scored as Highest_Runs_Scored
From TotalRunsScoredYear
Where  PeakRank=1
Order By Runs_Scored Desc;

#Looking into Yearly top batters and their career progression
With Career_progression as (
  Select Player_Name, Year, Runs_Scored , Sum( Runs_Scored) Over (Partition by Player_Name Order by Year ) as Cumulative_Runs,
  Dense_Rank() Over(Partition by Year Order by Runs_Scored Desc) as YearRank
  From PortfolioProject2.cricket_batting Bat
  )
Select Player_Name, Year, Runs_Scored, Cumulative_Runs, YearRank
From Career_progression
Where YearRank <=5
Order by Year Desc , YearRank
;

#Looking into Career Peak Analysis of Top Batters
With Career_Peak as(
   Select 
      Player_name, Year, Runs_Scored , 
      Avg (Cast(Runs_Scored as Float)) Over(Partition By Player_Name Order by Year Desc rows between 2 preceding and current row) as  Last_Three_Year_Avg,
      Max(Runs_Scored) Over(Partition by Player_Name) as Career_Best
      From PortfolioProject2.cricket_batting Bat
	  Order By Year Desc, Runs_Scored Desc
   )
Select Player_Name, Year, Runs_Scored, 
Round(Last_Three_Year_Avg,2) as Last_Three_Year_Avg , 
Career_Best,
Round((Cast(Runs_Scored as Float) / Career_Best),2) * 100 as Performance_percentage
From Career_Peak
Where Runs_Scored >= 500
Order by Year Desc, Runs_Scored Desc;

#looking in to consitency of batters in their peak performance
With Consistency as (
   Select 
          Player_Name,
		  Count(Distinct Year) as Seasons_Played,
          Max(Runs_Scored) as Highest_Score, Min(Runs_Scored) as Lowest_Score,
          Avg(Cast(Runs_Scored as Float)) as Avg_Runs,
          Stddev(Cast(Runs_Scored as Float )) as Std_Dev_Runs
   From PortfolioProject2.cricket_batting Bat
   Group By Player_Name
   Having Count(Distinct Year) >=5
)
Select Player_Name, Seasons_Played, Highest_Score, Lowest_Score,
       Round(Avg_Runs, 2) as Average_Runs,
       Round(Std_Dev_Runs,2) as Standard_Deviation,
       Round((Std_Dev_Runs/Nullif(Avg_Runs,0) * 100),2) as Coefficient_Of_Variation
From Consistency
Where Highest_Score >= 500
Order by Average_Runs Desc;

#Looking in to all-rpound performance of players over the years
Select distinct
Bat.Year,
Bat.Player_Name,
Bat.Matches_Batted,
Bow.Matches_Bowled,
Bat.Runs_Scored,
Bow.Wickets_Taken,
Bat.Batting_Average,
Bow.Bowling_Average,
Bat.Batting_Strike_Rate,
Bow.Economy_Rate
From PortfolioProject2.cricket_batting Bat
Inner join PortfolioProject2.cricket_bowling Bow
On Bat.Player_Name = Bow.Player_Name and Bat.Year=Bow.Year
Where Bat.Runs_Scored >= 0 And  Bow.Wickets_Taken >= 0
Order by Bat.Year Desc , Bat.Player_Name ;










