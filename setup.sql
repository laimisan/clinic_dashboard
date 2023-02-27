use clinic;

CREATE TABLE `client` (
    `id` varchar(255)  NOT NULL ,
    `client_name` varchar(255)  NOT NULL ,
    `phone` varchar(255) NOT NULL ,
    `email` varchar(255)  NOT NULL ,
    `how_discovered` varchar(255) NULL,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `appointment` (
    `id` varchar(255)  NOT NULL ,
    `client_id` varchar(255)  NOT NULL ,
    `treatment_id` varchar(255)  NOT NULL ,
    `app_date` date  NOT NULL ,
    `app_time` time  NOT NULL ,
    `emp_id` varchar(255)  NOT NULL ,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `employee` (
    `id` varchar(255)  NOT NULL ,
    `emp_name` varchar(255)  NOT NULL ,
    `payrate` decimal(3,2)  NOT NULL ,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `shift` (
    `id` varchar(255)  NOT NULL ,
    `emp_id` varchar(255)  NOT NULL ,
    `shift_date` date  NOT NULL ,
    `shift_start` time  NOT NULL ,
    `shift_end` time  NOT NULL ,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `day_off` (
    `id` varchar(255)  NOT NULL ,
    `emp_id` varchar(255)  NOT NULL ,
    `off_date` date  NOT NULL ,
    `reg_shift` varchar(255) NOT NULL,
    PRIMARY KEY (
        `id`
    )
);

CREATE TABLE `treatment` (
    `id` varchar(255)  NOT NULL ,
    `treatment_name` varchar(255)  NOT NULL ,
    `length` int  NOT NULL ,
    `price` int  NOT NULL ,
    PRIMARY KEY (
        `id`
    )
);

ALTER TABLE `appointment` ADD CONSTRAINT `fk_appointment_client_id` FOREIGN KEY(`client_id`)
REFERENCES `client` (`id`);

ALTER TABLE `appointment` ADD CONSTRAINT `fk_appointment_treatment_id` FOREIGN KEY(`treatment_id`)
REFERENCES `treatment` (`id`);

ALTER TABLE `appointment` ADD CONSTRAINT `fk_appointment_emp_id` FOREIGN KEY(`emp_id`)
REFERENCES `employee` (`id`);

ALTER TABLE `shift` ADD CONSTRAINT `fk_shift_emp_id` FOREIGN KEY(`emp_id`)
REFERENCES `employee` (`id`);

ALTER TABLE `day_off` ADD CONSTRAINT `fk_day_off_emp_id` FOREIGN KEY(`emp_id`)
REFERENCES `employee` (`id`);

-- adjusting settings to be able to import a local file

SHOW GLOBAL VARIABLES LIKE 'local_infile';
SET GLOBAL local_infile = true;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\client.csv' INTO TABLE client
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\employee.csv' INTO TABLE employee
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\treatment.csv' INTO TABLE treatment
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\shift.csv' INTO TABLE shift
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\holidays.csv' INTO TABLE day_off
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:\\Users\\laimi\\Desktop\\SQL dash\\mock_data\\appointment.csv' INTO TABLE appointment
FIELDS TERMINATED BY ',' LINES TERMINATED BY '\r\n' IGNORE 1 LINES;

