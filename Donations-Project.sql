/*
	The hypothetical non-profit group that you work for has asked you to run some queries to explore the data and fulfil requests.
	Theses requests focus on exploring donors and donations and developing email lists for further communication with the donors.
	
	The data is stored in 4 tables:
		donation - this table conatins record of all donations given to the organization
		donor - this table contains information about the donors who make donations
		organization - each donor belongs to an organization and this table contains infromation about them
		communication - donors are sent communications, this table represents a collection of these communications
*/


-- 1. Could you get me the names and emails of the top 10 donors of all time? We'd like to reach out to thank them for their support.

Select Top 10 donor.firstName, donor.lastName, donor.email, totals.total AS 'Total Donated'
From 
	(Select donation_idDonor AS 'totals_idDonor', SUM(amount) AS 'total' -- We need a sub-query here to calculate the total amount each donor has donated
	 From donation Group By donation_idDonor) AS totals
right join donor ON totals_idDonor = donor.idDonor -- Right join becuase we want only donors that exist in the donor table with their associated emails
Order By totals.total DESC; -- Order By totals descending so that the most generous donors appear on top


--- 2. Each donor belongs to an organization and each organization has a labeled sector that they operate in. Could you tell me which sectors have donated the most to our group?

Select organization.sector AS 'Organization Sector', SUM(donation.amount) AS 'Total Donated'
From ((donation left join donor ON donation_idDonor = donor.idDonor) -- Left join because we only want donors that appear in the donation table
	left join organization ON donor.donor_idOrg = organization.idOrg) -- Left join again because we only want organizations that have donations associated with them
Group By organization.sector -- Group By sector so that the SUM() function aggregates the donation amounts based on sector
Order By SUM(donation.amount) DESC; -- Must Order By the calculation and not the alias name


--- 3. I'm worried that the sums might be a poor measure of contribution to our group becuase there may be more organizations labeled as 'n/a'. As a follow-up, which sector contributes the highest AVERAGE donations?

Select organization.sector AS 'Organization Sector', AVG(donation.amount) AS 'Total Donated' -- This time we use the AVG() function to find the average donation amount
From ((donation left join donor ON donation_idDonor = donor.idDonor) -- Left join because we only want donors that appear in the donation table
	left join organization ON donor.donor_idOrg = organization.idOrg) -- Left join again because we only want organizations that have donations associated with them
Group By organization.sector -- Group By sector so that the AVG() function aggregates the donation amounts based on sector
Order By AVG(donation.amount) DESC; -- Must Order By the calculation and not the alias name


--- 4. It looks like Consumer Non-Durables is the sector that donates the highest average amount for their donations, so could you get me a list of emails of our donators from this sector? Reaching out to them seems like a good use of our time.

Select Distinct(donor.firstName + ' ' + donor.lastName) AS 'Donor Name', donor.email AS 'Email', organization.sector AS 'Sector' -- Select Distinct because we only want one row for each unique donator
From ((donation left join donor ON donation_idDonor = donor.idDonor) -- Left join because we only want donors that appear in the donation table
	left join organization ON donor.donor_idOrg = organization.idOrg) -- Left join again because we only want organizations that have donations associated with them
Where organization.sector = 'Consumer Non-Durables' -- Specify that we only want information on the donators in the 'Consumer Non-Durables' sector
Order By (donor.firstName + ' ' + donor.lastName); -- Reference the concatenated column by the calculation because we cannot refer to the aliased name


--- 5. We want to message our past donors who haven't donated in over 5 years, could you get me a list of those people and their emails? We think that reaching out could help encourage them to contribute again.

Select Distinct(donor.firstName + ' ' + donor.lastName) AS 'Donor Name', donor.email AS 'Email', latest_donation.date AS 'Last Donated' -- Select Distinct to get one row per donator
From 
	(Select donation.donation_idDonor AS 'idDonor', MAX(donation.date) AS 'date' -- Use a sub-query to create a collection of the latest communication date for each donor; MAX(date) is equivalent to the latest date
	 From donation
	 Group By donation.donation_idDonor) AS latest_donation
left join donor ON latest_donation.idDonor = donor.idDonor -- Left join to include only the donors that appear in the donation table
Where DATEDIFF(MONTH,latest_donation.date, GETDATE()) > 60 -- Use the DATEDIFF() function to calculate the number of MONTHs between the latest donation data and the current date obtained by the GETDATE() function. I am using 60 months instead of 5 years to round by month instead of year; resulting in more records returned
Order By (donor.firstName + ' ' + donor.lastName); -- Reference the concatenated column by the calculation because we cannot refer to the aliased name


--- 6. We want you to look at the data more in Tableau, which can connect to a MS SQL Server Instance. Could you write a custom query to use in Tableau that would populate a file with relevant donation information and then explore?

Select donation.date AS 'Date', donation.amount AS 'Amount', -- Information from the donation table
	(donor.firstName + donor.lastName) AS 'Name', donor.city AS 'City', donor.state AS 'State', -- Some relevant information from the donor table
	organization.orgName AS 'Organization', organization.sector AS 'Sector' -- Organization information to connect to each donor
From ((donation left join donor ON donation.donation_idDonor = donor.idDonor) -- Left join to include only donors that appear in the donation table
left join organization ON donor.donor_idOrg = organization.idOrg) -- Left join again to only include organizations that have a donator in the donations table
Order By donation.date; --- Tableau didn't like having an Order By clause or a semicolon though, so I removed them for import