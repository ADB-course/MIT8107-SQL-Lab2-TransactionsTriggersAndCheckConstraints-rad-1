-- Assignment Lab 2 - triggers
use strathmore_lab_transactions;
-- Show employees table creation script
show create table employees;
-- Creating employees_undo table script
CREATE TABLE `employees_undo` (
    `date_of_change` timestamp(2) NOT NULL DEFAULT CURRENT_TIMESTAMP(2)
COMMENT 'Records the date and time when the data was manipulated. This will
help to keep track of the changes made. The assumption is that no 2 users
will change the exact same record at the same time (with a precision of a
hundredth of a second, e.g., 4.26 seconds).',
  `employeeNumber` int NOT NULL,
  `lastName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `firstName` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `extension` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `officeCode` varchar(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `reportsTo` int DEFAULT NULL,
  `jobTitle` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `change_type` varchar(50) NOT NULL COMMENT 'Records the type of data
manipulation that was done, for example an insertion, an update, or a
deletion.',
PRIMARY KEY (`date_of_change`),
UNIQUE KEY `date_of_change_UNIQUE` (`date_of_change`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Create a trigger that is fired before updating an employee’s data
CREATE
TRIGGER TRG_BEFORE_UPDATE_ON_employees
BEFORE UPDATE ON employees FOR EACH ROW
INSERT INTO `employees_undo` SET
`date_of_change` = CURRENT_TIMESTAMP(2),
`employeeNumber` = OLD.`employeeNumber` ,
`lastName` = OLD.`lastName` ,
`firstName` = OLD.`firstName` ,
`extension` = OLD.`extension` ,
`email` = OLD.`email` ,
`officeCode` = OLD.`officeCode` ,
`reportsTo` = OLD.`reportsTo` ,
`jobTitle` = OLD.`jobTitle` ,
`change_type` = 'An update DML operation was executed';

-- Step 3 Show triggers
SHOW TRIGGERS;
-- Step 4. Confirm that the trigger is fired when an update is performed on the “employees” relation 
-- Update Mary's last name and email using the scripts below
UPDATE `employees` SET `lastName` = 'Muiruri' WHERE employeeNumber='1056';
update `employees` set email = 'mmuiruri@classicmodelcars.com' WHERE `employeeNumber` = '1056';

-- Execute the following command to view the updated data:
SELECT * FROM employees_undo;

-- STEP 5 - Create reminders table
  CREATE TABLE `customers_data_reminders` ( `customerNumber` int NOT NULL COMMENT 'Identifies the customer whose data is partly missing', `customers_data_reminders_timestamp` timestamp(2) NOT NULL DEFAULT CURRENT_TIMESTAMP(2) COMMENT 'Records the time when the missing data was detected', `customers_data_reminders_message` varchar(100) NOT NULL COMMENT 'Records a message that helps the customer service personnel to know what data is missing from the customer\'s record', `customers_data_reminders_status` tinyint NOT NULL DEFAULT '0' COMMENT 'Used to record the status of a reminder (0 if it has not yet been addressed and 1 if it has been addressed)', PRIMARY KEY (`customerNumber`,`customers_data_reminders_timestamp`,`customers_data_reminders_message`,`customers_data_reminders_status`), CONSTRAINT `FK_1_customers_TO_M_customers_data_reminders` FOREIGN KEY (`customerNumber`) REFERENCES `customers` (`customerNumber`) ON DELETE CASCADE ON UPDATE CASCADE ) ENGINE=InnoDB COMMENT='Used to remind the customer service personnel about a client\'s missing data. This enables them to ask the client to provide the data during the next interaction with the client.';

  -- STEP 6 Create a trigger that has multiple statements
DELIMITER $$
CREATE TRIGGER TRG_AFTER_INSERT_ON_customers AFTER
INSERT
       ON customers FOR EACH ROW
BEGIN
    IF
    NEW.postalCode IS NULL THEN
    INSERT INTO
           `customers_data_reminders`
               (
                   `customerNumber`                    ,
                   `customers_data_reminders_timestamp`,
                   `customers_data_reminders_message`
               )
    VALUES
           (
               NEW.customerNumber  ,
               CURRENT_TIMESTAMP(2),
               'Please remember to record the client\'s postal code'
           )
    ;
    END IF;
    IF
    NEW.salesRepEmployeeNumber IS NULL THEN
    INSERT INTO
           `customers_data_reminders`
               (
                   `customerNumber`                    ,
                   `customers_data_reminders_timestamp`,
                   `customers_data_reminders_message`
               )
    VALUES
           (
               NEW.customerNumber  ,
               CURRENT_TIMESTAMP(2),
               'Please remember to assign a sales representative to the client'
           )
    ;
    END IF;
    IF
    NEW.creditLimit IS NULL THEN
    INSERT INTO
           `customers_data_reminders`
               (
                   `customerNumber`                    ,
                   `customers_data_reminders_timestamp`,
                   `customers_data_reminders_message`
               )
    VALUES
           (
               NEW.customerNumber  ,
               CURRENT_TIMESTAMP(2),
               'Please remember to set the client\'s credit limit'
           )
    ;
    END IF;
    END$$
DELIMITER ;


-- STEP 7 Execute the statemeent below to confirm if the above trigger works
INSERT INTO
       `customers`
           (
               `customerNumber`  ,
               `customerName`    ,
               `contactLastName` ,
               `contactFirstName`,
               `phone`           ,
               `addressLine1`    ,
               `city`            ,
               `country`
           )
VALUES
       (
           '497'             ,
           'House of Leather',
           'Wambua'          ,
           'Gabriel'         ,
           '+254 720 123 456',
           '9 Agha Khan Walk',
           'Nairobi'         ,
           'Kenya'
       );

-- STEP 8 : Create a new table to store parts data
create table part (
part_no VARCHAR(18) primary key,
part_description VARCHAR(255),
part_supplier_tax_PIN VARCHAR (11) check (part_supplier_tax_PIN regexp
'^[A-Z]{1}[0-9]{9}[A-Z]{1}$'),
part_supplier_email VARCHAR (55),
part_buyingprice DECIMAL(10,
2 ) not null check (part_buyingprice >= 0),
part_sellingprice DECIMAL(10,
2) not null,
constraint CHK_part_sellingprice_GT_buyingprice check
(part_sellingprice >= part_buyingprice),
constraint CHK_part_valid_supplier_email check (part_supplier_email
regexp '^[a-zA-Z0-9]{3,}@[a-zA-Z0-9]{1,}\\.[a-zA-Z0-9.]{1,}$')
);

-- STEP 9. Create the following user-defined error in a trigger
DELIMITER //
CREATE TRIGGER TRG_BEFORE_UPDATE_ON_part BEFORE
UPDATE
       ON part FOR EACH ROW
BEGIN
    DECLARE errorMessage VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLSTATE '45000'
        BEGIN
            RESIGNAL
            SET MESSAGE_TEXT = errorMessage;
        END
    ;
    SET errorMessage = CONCAT('The new selling price of ', NEW.part_sellingprice, ' cannot be 2 times greater than the current selling price of ', OLD.part_sellingprice);
    IF
    NEW.part_sellingprice > OLD.part_sellingprice * 2 THEN SIGNAL SQLSTATE '45000';
    END IF;
END
// DELIMITER ;

-- STEP 10 Confirm that the static, dynamic, and semantic constraints are working
-- This failed due to the check constraint on selling price must be greater or equal to buying price
INSERT INTO `part` (`part_no`, `part_description`, `part_supplier_tax_PIN`,
`part_supplier_email`, `part_buyingprice`, `part_sellingprice`)
VALUES ('001', 'The tyres of a 1958 Chevy Corvette Limited Edition',
'P05120157U', 'toysRus@gmail', '100', '50');