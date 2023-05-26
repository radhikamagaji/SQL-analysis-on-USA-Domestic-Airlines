-- queries

SELECT * FROM normalizedschema.flight1;
SELECT * FROM normalizedschema.airports;
SELECT * FROM normalizedschema.marketing_carrier_master;
SELECT * FROM normalizedschema.operating_carrier_master;
SELECT * FROM normalizedschema.arr_performance;
SELECT * FROM normalizedschema.dep_performance;
SELECT * FROM normalizedschema.flights_summaries;
SELECT * FROM normalizedschema.canc_divr;


-- 1. The total number of flights that took off in each year
SELECT DATA_TYPE from INFORMATION_SCHEMA.COLUMNS where
table_schema = 'normalizedschema' and table_name = 'airline1';

select count(*) from flight1 where Year(FlightDate) = '1998';
select count(*) from flight1 where Year(FlightDate) = '1999';
select count(*) from flight1 where Year(FlightDate) = '2015';
select count(*) from flight1 where Year(FlightDate) = '2016';
select count(*) from flight1 where Year(FlightDate) = '2020';
select count(*) from flight1 where Year(FlightDate) = '2021';

-- Query 1
-- 2. no. Cancellations flights by airport and by Carrier
SELECT airports.CITY_NAME as "Origin Airport", count(canc_divr.MKT_CARRIER_AIRLINE_ID) as "Number of cancelled Flights",
 airline_l_unique_carriers.Description as "Carrier Name", year(canc_divr.FlightDate) as 'Year'
	FROM normalizedschema.canc_divr, normalizedschema.airports, normalizedschema.marketing_carrier_master, 
    projectpart1.airline_l_unique_carriers
	 where canc_divr.Cancelled <> 0
     and airports.AIRPORT_ID = canc_divr.OriginAirportID
     and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = canc_divr.MKT_CARRIER_AIRLINE_ID
     and marketing_carrier_master.MKT_UNIQUE_CARRIER = airline_l_unique_carriers.code
	 group by year(canc_divr.FlightDate),canc_divr.OriginAirportID, airline_l_unique_carriers.Description
     order by count(canc_divr.MKT_CARRIER_AIRLINE_ID) desc, airports.CITY_NAME asc;
     


-- 3. no. Cancellations flights by airport and by Carrier for 2021
SELECT airports.CITY_NAME as "Origin Airport", count(canc_divr.MKT_CARRIER_AIRLINE_ID) as "Number of cancelled Flights in 2021",
 airline_l_unique_carriers.Description as "Carrier Name" 
	FROM normalizedschema.canc_divr, normalizedschema.airports, normalizedschema.marketing_carrier_master, 
    projectpart1.airline_l_unique_carriers
	 where canc_divr.Cancelled <> 0
     and airports.AIRPORT_ID = canc_divr.OriginAirportID
     and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = canc_divr.MKT_CARRIER_AIRLINE_ID
     and marketing_carrier_master.MKT_UNIQUE_CARRIER = airline_l_unique_carriers.code
     and year(canc_divr.FlightDate) = '2021'
	 group by canc_divr.OriginAirportID, airline_l_unique_carriers.Description
     order by count(canc_divr.MKT_CARRIER_AIRLINE_ID) desc, airports.CITY_NAME asc;


-- 4.  Calculating Total cancellations per City of Origin using Window funtion in the year 2021
SELECT airports.CITY_NAME as "Origin Airport", count(canc_divr.MKT_CARRIER_AIRLINE_ID) as "Number of cancelled Flights in 2021 per Carrier",
 airline_l_unique_carriers.Description as "Carrier Name", 
 sum(count(canc_divr.MKT_CARRIER_AIRLINE_ID)) over (Partition by airports.CITY_NAME) as "Total Cancellations from Origin"
	FROM normalizedschema.canc_divr, normalizedschema.airports, normalizedschema.marketing_carrier_master, 
    projectpart1.airline_l_unique_carriers
	 where canc_divr.Cancelled <> 0
     and airports.AIRPORT_ID = canc_divr.OriginAirportID
     and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = canc_divr.MKT_CARRIER_AIRLINE_ID
     and marketing_carrier_master.MKT_UNIQUE_CARRIER = airline_l_unique_carriers.code
     and year(canc_divr.FlightDate) = '2021'
	 group by canc_divr.OriginAirportID, airline_l_unique_carriers.Description
     order by count(canc_divr.MKT_CARRIER_AIRLINE_ID) desc, airports.CITY_NAME asc;
     
	-- 5. All AA Flights Arrived later than 60min from scheduled time
   
	Select arr_performance.OP_CARRIER_FL_NUM as "Count of Flights > 60min dep delay",
    arr_performance.Tail_Number as "Tail Number",
    arr_performance.ArrDelay as "Arrival Delay in Mins",
    airports.CITY_NAME as "Destination",
    year(arr_performance.FlightDate) 
    from   arr_performance, airports
    where    MKT_CARRIER_AIRLINE_ID in 
		(select MKT_CARRIER_AIRLINE_ID from normalizedschema.marketing_carrier_master where MKT_UNIQUE_CARRIER = 'AA')
	and airports.AIRPORT_SEQ_ID = arr_performance.DestAirportSeqID
    and arr_performance.ArrivalDelayGroups >= 4
    and arr_performance.ArrDelay is not null
    order by ArrDelay desc;
    
    
    
    -- 6. Busiest Airports by number of flights that took off - Departure
     
	select count(Dep_Performance.OriginAirportID) as '# of Flights', airports.CITY_NAME as 'Departure City Name' ,  Year(FlightDate) as 'Year'
    from Dep_Performance,airports
    where Dep_Performance.DepTime is not null 
    and Dep_Performance.OriginAirportID = airports.AIRPORT_ID 
    group by year(flightDate),Dep_Performance.OriginAirportID
    order by count(Dep_Performance.deptime) desc;
    
    -- the busiest Airport looks like Atlanta, GA. 
    
-- 7 Highest time spent during Taxi-in (exceeding 30 mins) time per arrival airport 


SELECT max(arr_performance.taxiin) as "Time taken to Taxi-in in mins", arr_performance.ArrDelay as "Arrival Delay time", airports.CITY_NAME as "Destination Airport", 
arr_performance.OP_CARRIER_FL_NUM as "Flight Number", year(arr_performance.FlightDate) as "Year" 
FROM normalizedschema.arr_performance, normalizedschema.airports
where arr_performance.OriginAirportID = airports.AIRPORT_ID
and arr_performance.taxiin > 30
group by OriginAirportID
order by max(taxiin) desc;

-- From the results here, it looks like the highest taxi in times were during end of beginning of the year
-- which seems reasonable as air traffic could be higher as it is the holiday season.
    
-- 8. Average Taxi-in time per airport 
 

SELECT avg(arr_performance.taxiin) as "Average Time taken to Taxi-in in mins", airports.CITY_NAME as "Destination Airport"
FROM normalizedschema.arr_performance, normalizedschema.airports
where arr_performance.OriginAirportID = airports.AIRPORT_ID
group by OriginAirportID
order by avg(arr_performance.taxiin) asc;

-- from the results obtained, we see that the least average taxi-in time is at Alaska State
-- which is reasonable as the habitat is not great in number and that people travel there only during vacation time and not round the year

-- 9. Airline carriers with number of ZERO Delays per airport or the number of flights that left on time.
select count(dep_performance.MKT_CARRIER_AIRLINE_ID) as "Number of Airlines with Zero Delays", 
projectpart1.airline_l_unique_carriers.Description as "Airline Carrier", normalizedschema.airports.CITY_NAME as "Departure Airport" , year(normalizedschema.dep_performance.flightdate) as 'Year'
from normalizedschema.dep_performance, projectpart1.airline_l_unique_carriers,normalizedschema.marketing_carrier_master,normalizedschema.airports
where 
 dep_performance.MKT_CARRIER_AIRLINE_ID = marketing_carrier_master.MKT_CARRIER_AIRLINE_ID 
 and marketing_carrier_master.MKT_UNIQUE_CARRIER = airline_l_unique_carriers.Code
 and dep_performance.OriginAirportID = airports.AIRPORT_ID
 and depdelay = 0
 group by dep_performance.OriginAirportID, dep_performance.MKT_CARRIER_AIRLINE_ID, year(FlightDate)
 order by count(dep_performance.MKT_CARRIER_AIRLINE_ID) desc;
 
 -- 10. Airline carriers with early than scheduled departures per airport in 2021
 select count(dep_performance.MKT_CARRIER_AIRLINE_ID) as "Number of Flights", 
projectpart1.airline_l_unique_carriers.Description as "Airline Carrier", airports.CITY_NAME as "Departure Airport", year(dep_performance.flightdate) as 'Year'
from normalizedschema.dep_performance, projectpart1.airline_l_unique_carriers,normalizedschema.marketing_carrier_master,normalizedschema.airports
where 
 dep_performance.MKT_CARRIER_AIRLINE_ID = marketing_carrier_master.MKT_CARRIER_AIRLINE_ID 
 and marketing_carrier_master.MKT_UNIQUE_CARRIER = airline_l_unique_carriers.Code
 and dep_performance.OriginAirportID = airports.AIRPORT_ID
 and depdelay < 0  
 group by dep_performance.OriginAirportID, dep_performance.MKT_CARRIER_AIRLINE_ID
 order by count(dep_performance.MKT_CARRIER_AIRLINE_ID) desc;
 
 
 --  From the above 2 queries, one can say that the flights departing from Altanta, GA and Dallas/Fort Woth, TX have 
 -- always departed on time or have departed even earlier than scheduled. This suggests, Airport operations are these two cities
-- are much more conducive compared to other cities. Also, Delta Airlines and American Airlines hubs at these cities and thus looks like 
-- operations are much more easier.
 
 -- 11. Airlines with weather delays delayed by >20 mins in 2021. 
 -- Distributed per airline per departure airport and total delays by departure airport


select count(dep_performance.op_carrier_fl_num) as "Count of Delayed Flights",
airports.CITY_NAME as "Departure Airport",projectpart1.airline_l_unique_carriers.description as "Carrier Airlines",
sum(count(dep_performance.op_carrier_fl_num)) over (Partition by airports.CITY_NAME) as "Total delays per Airport"
 from dep_performance,airports,projectpart1.airline_l_unique_carriers,marketing_carrier_master where 
dep_performance.depdelay > 20
and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = dep_performance.MKT_CARRIER_AIRLINE_ID
and marketing_carrier_master.MKT_UNIQUE_CARRIER = projectpart1.airline_l_unique_carriers.code
and dep_performance.OriginAirportID = airports.AIRPORT_ID
and year(dep_performance.FlightDate) = '2021' 
and dep_performance.originairportid in (select originairportID from  normalizedschema.cause_delay  where weatherdelay > 0)
group by dep_performance.OriginAirportID, Description
order by count(dep_performance.op_carrier_fl_num) desc;


-- 12. Airlines with weather delays delayed by >20 mins in 2021. 
 -- Distributed per airline per departure airport and total delays by Airlines

 
select count(dep_performance.op_carrier_fl_num) as "Count of Delayed Flights",
airports.CITY_NAME as "Departure Airport",projectpart1.airline_l_unique_carriers.description as "Carrier Airlines",
sum(count(dep_performance.op_carrier_fl_num)) over (partition by airline_l_unique_carriers.description) as "Total delays per Airlines"
 from dep_performance,airports,projectpart1.airline_l_unique_carriers,marketing_carrier_master where 
dep_performance.depdelay > 20
and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = dep_performance.MKT_CARRIER_AIRLINE_ID
and marketing_carrier_master.MKT_UNIQUE_CARRIER = projectpart1.airline_l_unique_carriers.code
and dep_performance.OriginAirportID = airports.AIRPORT_ID
and year(FlightDate) = '2021'
and dep_performance.originairportid in (select originairportID from normalizedschema.cause_delay where weatherdelay > 0)
group by dep_performance.OriginAirportID, Description
order by count(dep_performance.op_carrier_fl_num) desc;


-- Query 3
-- departure delay performance of carriers  in 2020 and 2021

select normalizedschema.dep_performance.OriginAirportID, normalizedschema.dep_performance.OP_CARRIER_FL_NUM , airports.CITY_NAME, year(dep_performance.FlightDate)
from dep_performance, airports
where dep_performance.DepartureDelayGroups > 0
and (year(dep_performance.FlightDate) = '2021' OR
	year(dep_performance.FlightDate) = '2020');


-- Query 15 Arrival delay vs Dep delay for american airlines - 19805 in the year 2021 only
 create view c as SELECT dep_performance.DepDelay as "Departure Delay in min", arr_performance.ArrDelay as "Arrival Delay in min", airports.CITY_NAME as "Destination Airport", 
arr_performance.OP_CARRIER_FL_NUM as "Flight Number", arr_performance.FlightDate, year(arr_performance.FlightDate) as "Year", marketing_carrier_master.MKT_CARRIER_AIRLINE_ID
FROM normalizedschema.arr_performance, normalizedschema.dep_performance, normalizedschema.airports, marketing_carrier_master
where arr_performance.DestAirportID = airports.AIRPORT_ID
and arr_performance.OP_CARRIER_FL_NUM = dep_performance.OP_CARRIER_FL_NUM
and normalizedschema.arr_performance.Flightdate like '%2021%'
and arr_performance.ArrDelay > 30
and dep_performance.DepDelay > 30
and arr_performance.MKT_CARRIER_AIRLINE_ID = marketing_carrier_master.MKT_CARRIER_AIRLINE_ID
and marketing_carrier_master.MKT_CARRIER_AIRLINE_ID = '19805'
and dep_performance.MKT_CARRIER_AIRLINE_ID = arr_performance.MKT_CARRIER_AIRLINE_ID;

-- 16. Flights that had arrival  delay > 30min was at what time block only year 2021
SELECT arr_performance.ArrDelay, arr_performance.ArrTimeBlk, arr_performance.FlightDate, airline_l_deparrblk.Description as 'Time Block', arr_performance.OP_CARRIER_FL_NUM as 'Flight Number'
	FROM normalizedschema.arr_performance, projectpart1.airline_l_deparrblk
    where arr_performance.ArrDelay > 30
    and airline_l_deparrblk.code = arr_performance.ArrTimeBlk
    and year(FlightDate) = '2021'
    order by arr_performance.ArrTimeBlk;
    
    SELECT distinct MKT_CARRIER_AIRLINE_ID, FlightDate, OriginAirportID
FROM dep_performance
where DepTime > CRSDepTime AND MKT_CARRIER_AIRLINE_ID 
IN(SELECT MKT_CARRIER_AIRLINE_ID from arr_performance where ArrTime <= CRSArrTime);
   
   
-- Query 17
    select CITY_NAME as "Origin Airport", OP_CARRIER_FL_NUM as "Flight Number", year(FlightDate) as "Year",
 CancellationCode as "Cancellation Code", description as "Cancellation Reason",
 count(canc_divr.OP_CARRIER_FL_NUM ) over (Partition by airports.CITY_NAME) as "Total cancellations per Airport"
from canc_divr,projectpart1.airline_l_cancellation,airports
where canc_divr.CancellationCode = projectpart1.airline_l_cancellation.code
and canc_divr.OriginAirportID = airports.AIRPORT_ID
and cancellationcode in ('A','B','C','D');
