# Table and Field Descriptions

### donation - this table conatins record of all donations given to the organization
* idDonations - primary key to uniquely identify a donation entry
* donations_idDonor - id of the donor associated with the donation (foreign key for donor table)
* date - date of the donation
* amount - amount of the donation in USD


### donor - this table contains information about the donors who make donations
* idDonor - primary key to uniquely identify a donor
* donor_idOrg - id of the organization that the donor belongs to (foreign key for organization table)
* firstName - first name of donor
* lastName - last name of donor
* street - street number of donor address
* city - city of donor address
* state - two letter abbreviation of US state of donor address
* email - email address of donor for contact


### organization - each donor belongs to an organization and this table contains infromation about them
* idOrg - primary key to uniquely identify an organization
* orgName - name of the organization
* sector - sector that the organization falls in (tech, health, etc.)


### communication - donors are sent communications, this table represents a collection of these communications
* idCommunication - primary key to uniquely identify a communication with a donor
* communication_idDonor - id of the donor that was communicated with (foreign key for the donor table)
* date - date of the communication
* notes - notes about the communication (not actual words)

