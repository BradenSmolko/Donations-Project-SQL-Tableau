/*
	Your boss at the hypothetical non-profit group that you work for has asked you to run some queries to explore the data and fulfill some requests.
	Theses requests focus on exploring your donors and donations, and developing email lists for further communication with the donors.
	
	The data is stored in 4 tables:
		donation - this table conatins record of all donations given to the organization
		donor - this table contains information about the donors who make donations
		organization - each donor belongs to an organization and this table contains infromation about them
		communication - donors are sent communications, this table represents a collection of these communications

	I will be connecting entries in the donation table with their respective donors and organization information multiple times, so I create a view below to store this.
*/
Drop View If Exists [donation info];
GO

Create View [donation info] AS
	Select
		donation.*,
		donor.*,
		organization.*
	From ((donation 
	Left Join donor -- Left join because we only want donors that appear in the donation table
		ON donation_idDonor = donor.idDonor) 
	Left Join organization -- Left join again because we only want organizations that have donors and donations associated with them
		ON donor.donor_idOrg = organization.idOrg);
GO -- MS SQL requires that the Create View statement is the only statement in a batch, so to keep this all in one script, I break it up with GO


/*
	REQUEST 1:

	Could you get me the names and emails of the top 10 donors of all time? 
	We'd like to reach out to thank them for their support.
*/
With donor_total AS ( -- Create a sub-query block to calculate donor total donations, name it donor_total
	Select 
		donation_idDonor AS 'donor_total_idDonor',
		SUM(amount) AS 'total' 
	 From donation 
	 Group By donation_idDonor
	)

Select Top 10 -- Select Top 10 to return only 10 records
	(donor.firstName + ' ' + donor.lastName) AS 'Name', -- Concatenate first name and last name to create one column in results
	donor.email AS 'Email',
	donor_total.total AS 'Total Donated' 
From donor_total
Right Join donor
	ON donor_total_idDonor = donor.idDonor -- Right join becuase we want only donors that exist in the donor table with their associated emails
Order By donor_total.total DESC; -- Order By total donations descending so that the most generous donors appear on top


/*
	REQUEST 2:

	Each donor belongs to an organization and each organization has a labeled sector that they operate in. 
	Could you tell me how much each sector has donated to our group?
*/
Select 
	[donation info].sector AS 'Organization Sector',
	SUM([donation info].amount) AS 'Total Donated'
From [donation info] 
Group By [donation info].sector -- Group By sector so that the SUM() function aggregates the donation amounts based on sector
Order By SUM([donation info].amount) DESC; -- Must Order By the calculation and not the alias name


/*
	REQUEST 3:

	I'm also curious to find out which sector makes the largest donations on average so that we can target those donors for communication. 
	So, as a follow-up, which sector contributes the the most money per donation on average?
*/
Select 
	[donation info].sector AS 'Organization Sector',
	AVG([donation info].amount) AS 'Average Donation Amount' -- This time we use the AVG() function to find the average donation amount
From [donation info]
Group By [donation info].sector -- Group By sector so that the AVG() function aggregates the donation amounts based on sector
Order By AVG([donation info].amount) DESC; -- Must Order By the calculation and not the alias name


/*
	REQUEST 4:

	It looks like Consumer Non-Durables is the sector that donates the highest average amount per donation, so could you get me a list of emails 
	of our donors from this sector? Reaching out to them seems like a good use of our time.
*/
Select Distinct -- Select Distinct because we only want one row for each unique donor
	([donation info].firstName + ' ' + [donation info].lastName) AS 'Donor Name',
	[donation info].email AS 'Email',
	[donation info].sector AS 'Sector'
From [donation info]
Where [donation info].sector = 'Consumer Non-Durables' -- Specify that we only want information on the donors in the 'Consumer Non-Durables' sector
Order By ([donation info].firstName + ' ' + [donation info].lastName); -- Reference the concatenated column by the calculation because we cannot refer to the aliased name


/*
	REQUEST 5:

	We want to message our past donors who haven't donated in over 5 years, could you get me a list of those people and their emails?
	We think that reaching out could help encourage them to contribute again. We also don't want to spam our donors with emails though,
	so could you also make sure to filter out any donors who we've communicated with in the past 1.5 years?
*/
With latest_donation AS ( -- Create a sub-query block that returns a collection of the latest donation date for each donor
	Select
		donation.donation_idDonor AS 'latest_donation_idDonor',
		MAX(donation.date) AS 'date' -- MAX(date) is equivalent to the latest date
	From donation
	Group By donation.donation_idDonor
),

latest_communication AS ( -- Create a sub-query block that returns a collection of the latest communication date for each donor
	Select
		communication.communication_idDonor AS 'latest_communication_idDonor',
		MAX(communication.date) AS 'date' -- MAX(date) is equivalent to the latest date
	From communication
	Group By communication.communication_idDonor
)

Select Distinct -- Select Distinct to get one row per donor
	(donor.firstName + ' ' + donor.lastName) AS 'Donor Name',
	donor.email AS 'Email',
	latest_donation.date AS 'Last Donated' 
From ((latest_donation
Left Join donor -- Left join to include only the donors that appear in the donation table
	ON latest_donation.latest_donation_idDonor = donor.idDonor)
Left Join latest_communication -- Left join to include only communications with matching donors in the table
	ON donor.idDonor = latest_communication.latest_communication_idDonor)
/*
Use the DATEDIFF() function to calculate the number of months between the latest donation date and the current date using GETDATE().
I pass MONTH into the function instead of YEAR to get the date difference in months which internally rounds by months instead of years.
This difference in rounding ends up returns more records that are still accurately within the time period specified.

In the first part of the Where clause, I filter out any donors that have donated in the past 60 months (5 years).
In the second part of the Where clause, I filter our any donors that have received communication from the group in the past 18 months (1.5 years)
*/
Where DATEDIFF(MONTH, latest_donation.date, GETDATE()) > 60
	AND DATEDIFF(MONTH, latest_communication.date, GETDATE()) < 18
Order By (donor.firstName + ' ' + donor.lastName); -- Reference the concatenated column by the calculation because we cannot refer to the aliased name


/*
	REQUEST 6:

	We want you to look at the data more in Tableau, which we know can connect directly to this database server. 
	Could you write a custom query to use in Tableau that would create a data source with relevant donation information to build some visuals?
*/
-- I don't use the [donation info] view here so that I can paste this part into Tableau without needing the view to exist
Select donation.date AS 'Date', donation.amount AS 'Amount', -- Information from the donation table
	(donor.firstName + donor.lastName) AS 'Name', donor.city AS 'City', donor.state AS 'State', -- Some relevant information from the donor table
	organization.orgName AS 'Organization', organization.sector AS 'Sector' -- Organization information to connect to each donor
From ((donation
Left Join donor
	ON donation.donation_idDonor = donor.idDonor) -- Left join to include only donors that appear in the donation table
Left Join organization
	ON donor.donor_idOrg = organization.idOrg) -- Left join again to only include organizations that have a donor in the donations table
Order By donation.date; -- Tableau treats custom queries like a view, so we can't actually include this like when pasting into Tableau