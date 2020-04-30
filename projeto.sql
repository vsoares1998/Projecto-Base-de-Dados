USE guest;

CREATE TABLE IF NOT EXISTS CLIENT
(
	Client_Id INT(11) NOT NULL PRIMARY KEY AUTO_INCREMENT,
	Name VARCHAR(128) NOT NULL,
	Active VARCHAR(5) NOT NULL,
	Email VARCHAR(50),
	Country VARCHAR(30) NOT NULL,
	Address_Flor VARCHAR(12),
	Address_Street VARCHAR(128) NOT NULL,
	Address_City VARCHAR(30) NOT NULL,
	Address_DoorN INT NOT NULL,
	Sex ENUM('M', 'F') NOT NULL,
	BirthDate DATE NOT NULL,
  Age INT
);

CREATE TABLE IF NOT EXISTS PHONE
(
	Client_Id INT PRIMARY KEY,
	Phone VARCHAR(10) NOT NULL,
	FOREIGN KEY (Client_Id) REFERENCES CLIENT(Client_Id) ON UPDATE CASCADE
);


CREATE TABLE IF NOT EXISTS EXEMPLARY
(
		Code INT PRIMARY KEY AUTO_INCREMENT,
		Location_Shelf VARCHAR(15) NOT NULL,
		Location_Stand VARCHAR(15) NOT NULL,
		ISBN INT NOT NULL,
		Available VARCHAR(5) NOT NULL

	/*	FOREIGN KEY (ISBN) REFERENCES BOOK(ISBN) ON DELETE CASCADE*/
);


CREATE TABLE IF NOT EXISTS RENT
(
	Start_Date DATE NOT NULL,
	End_Date DATE,
	StaffId INT NOT NULL,
	RentId INT AUTO_INCREMENT,
	ClientId INT NOT NULL,
	Fine DECIMAL(4,2),
	Code INT NOT NULL,
	PRIMARY KEY (RentId,ClientId,Code),
	FOREIGN KEY (ClientId) REFERENCES CLIENT(Client_Id) ON UPDATE CASCADE,
	FOREIGN KEY (Code) REFERENCES EXEMPLARY(Code) ON UPDATE CASCADE
);


/*
ERROR 1418 (HY000): This function has none of DETERMINISTIC, NO SQL,
or READS SQL DATA in its declaration and binary logging is enabled
(you *might* want to use the less safe log_bin_trust_function_creators variable)


Execute o seguinte no console do MySQL:

SET GLOBAL log_bin_trust_function_creators = 1;

Adicione o seguinte ao arquivo de configuração mysql.ini:

log_bin_trust_function_creators = 1;

*/



DROP FUNCTION IF EXISTS getAge;
DELIMITER $

CREATE FUNCTION getAge(BirthDate DATE)
RETURNS INT
BEGIN
  DECLARE Age INT;
	SELECT DATE_FORMAT(FROM_DAYS(DATEDIFF(CURDATE(), BirthDate)),"%Y")+ 0 INTO Age;
  RETURN Age;
END $
DELIMITER ;

/*DROP FUNCTION IF EXISTS setActive;
DELIMITER $

CREATE FUNCTION setActive(Active INT)
RETURNS VARCHAR(5)
BEGIN
  DECLARE active VARCHAR(5);
		IF Active = 0 THEN
			SET active = "True";
		END IF;
		IF Active = 1 THEN
			SET active = "False";
		END IF;
  RETURN active;
END $
DELIMITER ;
*/

DROP FUNCTION IF EXISTS fine;
DELIMITER $

CREATE FUNCTION fine(Start_Date DATE,End_Date DATE)
RETURNS DECIMAL(4,2)
BEGIN
	 DECLARE Fine DECIMAL(4,2);
	 DECLARE DIASDECORRIDOS INT;
	 SET Fine = 0.00;
	 IF End_Date IS NULL THEN
	 		SET End_Date = CURDATE();
			SELECT (DATE(End_Date)-DATE(Start_Date)) INTO DIASDECORRIDOS;
			IF DIASDECORRIDOS >= 15 THEN
			  SET Fine = 1.0 + 0.15 * DIASDECORRIDOS;
			  IF DIASDECORRIDOS >= 30 THEN
			    SET Fine = Fine * 0.5;
			    IF DIASDECORRIDOS >= 40 THEN
			      SET Fine = Fine * 0.75;
			    END IF;
			  END IF;
	    END IF;
	END IF;
	RETURN Fine;
END $

DELIMITER ;


DROP PROCEDURE IF EXISTS AgeCalc;
DELIMITER $
CREATE PROCEDURE AgeCalc
(IN client_Id INT,IN Name VARCHAR(128),IN Active VARCHAR(5), IN Email VARCHAR(50),
IN Country VARCHAR(30), IN Address_Flor VARCHAR(12),IN Address_Street VARCHAR(128) ,
IN Address_City VARCHAR(30), IN Address_DoorN INT , IN Sex ENUM('M', 'F') , IN BirthDate DATE,IN Phone INT,
 OUT Age INT)
BEGIN
  -- Obtém valor a cobrar usando função getChargeValue()
  SET Age = getAge(BirthDate);

  -- Insere registo na tabela CLIENT.
  INSERT INTO
				CLIENT(Client_Id,Name,Active,Email,Country,Address_Flor,Address_City,Address_Street,Address_DoorN,Sex,BirthDate,Age)
  VALUES (client_Id,Name,active,Email,Country,Address_Flor,Address_City,Address_Street,Address_DoorN,Sex,BirthDate,Age);
  -- Obtém id de registo inserido (função LAST_INSERT_ID)

	INSERT INTO
	       PHONE(Client_Id,Phone)
	VALUES
				(client_Id,Phone);

  SET client_Id = LAST_INSERT_ID();
END $
DELIMITER ;

CALL AgeCalc(1,'Pedro','Yes','tester@gmail.com','Portugal',NULL,'Porto','Avenida dos Aliados','1','M','1998-11-23',912458454,@Age);
CALL AgeCalc(2,'Pedro','NO','tester@gmail.com','Portugal',NULL,'Porto','Avenida dos Aliados','1','M','1998-11-23',963850741,@Age);


DROP PROCEDURE IF EXISTS InsertRent;
DELIMITER $
CREATE PROCEDURE InsertRent
(IN Start_Date DATE,IN End_Date DATE,IN StaffId INT, IN RentId INT,
IN clientId INT,IN Code INT,
 OUT Fine INT)
BEGIN

  SET Fine = fine(Start_Date,End_Date);

  INSERT INTO
				RENT(Start_Date,End_Date,StaffId,ClientId,Fine,Code)
  VALUES (Start_Date,End_Date,StaffId,clientId,Fine,Code);

   -- SET client_Id = LAST_INSERT_ID();
END $
DELIMITER ;




INSERT INTO
			EXEMPLARY(Location_Shelf,Location_Stand,ISBN,Available)
VALUES
			('estante 1','partleira 2',12457892,'YES');


CALL InsertRent('2020-01-01',NULL,1,1,1,1,@Fine);


/*
INSERT INTO
			RENT(Start_Date,End_Date,StaffId,ClientId,Code)
VALUES
			('1998-01-01',NULL,1,1,1);*/
