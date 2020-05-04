DROP DATABASE TESTER;

CREATE DATABASE TESTER;

USE TESTER;

SET GLOBAL log_bin_trust_function_creators = 1;

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

CREATE TABLE IF NOT EXISTS BOOK
(

	Title VARCHAR(25) NOT NULL,
	Edition VARCHAR(25),
	N_Available INT,
	ISBN INT PRIMARY KEY
);


CREATE TABLE IF NOT EXISTS EXEMPLARY
(
		Code INT PRIMARY KEY AUTO_INCREMENT,
		Location_Shelf VARCHAR(15) NOT NULL,
		Location_Stand VARCHAR(15) NOT NULL,
		ISBN INT NOT NULL,
		Available VARCHAR(5) NOT NULL,
		DateIn DATE NOT NULL,
	  FOREIGN KEY (ISBN) REFERENCES BOOK(ISBN) ON UPDATE CASCADE
);

CREATE TABLE IF NOT EXISTS CATEGORY
(
	CategoryId INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	Name VARCHAR(25) NOT NULL,
	FOREIGN KEY (CategoryId) REFERENCES BOOK(ISBN)
);



CREATE TABLE IF NOT EXISTS AUTHOR
(
	AuthorId INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
	Name VARCHAR(25),
	Sex ENUM('M', 'F') NOT NULL,
	Country VARCHAR(25)
);

CREATE TABLE IF NOT EXISTS WRITTEN
(
	Author INT NOT NULL,
	Book INT NOT NULL,
	PRIMARY KEY(Author,Book),
	FOREIGN KEY (Author) REFERENCES AUTHOR(AuthorId),
	FOREIGN KEY (Book) REFERENCES BOOK(ISBN)
);


CREATE TABLE  IF NOT EXISTS STAFF(
  StaffId INT(11) NOT NULL AUTO_INCREMENT,
  SupervisorId INT(11) DEFAULT NULL,
  Job VARCHAR(32) NOT NULL,
  Name VARCHAR(64) NOT NULL,
  PRIMARY KEY (StaffId),
  KEY Supervisor (SupervisorId),
  CONSTRAINT staff_ibfk_1 FOREIGN KEY (SupervisorId) REFERENCES STAFF (StaffId)
) ;


CREATE TABLE IF NOT EXISTS HAVE
(
	ISBN INT NOT NULL,
	Code INT NOT NULL,
	DateIn DATE NOT NULL,
	PRIMARY KEY (Code),
	FOREIGN KEY (Code) REFERENCES EXEMPLARY(Code) ON DELETE CASCADE
);

DROP TRIGGER IF EXISTS AfterAddEXEMPLARY;
DELIMITER $

CREATE TRIGGER AfterAddEXEMPLARY
AFTER INSERT ON EXEMPLARY FOR EACH ROW
BEGIN
	DECLARE n INT;
	SET n = getBooks(NEW.ISBN);
	UPDATE BOOK SET N_Available = n WHERE NEW.ISBN = ISBN;
	INSERT INTO HAVE (ISBN,Code,DateIn)
	VALUES (NEW.ISBN,NEW.Code,CURDATE());

END $

DELIMITER ;

DROP TRIGGER IF EXISTS AfterAddEX;
DELIMITER $

CREATE TRIGGER AfterAddEX
AFTER INSERT ON EXEMPLARY FOR EACH ROW
BEGIN
	DECLARE EXEMPLARYS BOOL;
	DECLARE error CONDITION FOR SQLSTATE '99999';
	SET EXEMPLARYS = TRUE;
	SELECT FALSE INTO EXEMPLARYS FROM BOOK WHERE ISBN = NEW.ISBN;

	IF EXEMPLARYS THEN
					SIGNAL error SET MESSAGE_TEXT = 'Este Livro NÃO está registado';
	END IF;
END $

DELIMITER ;

/*
DROP TRIGGER IF EXISTS BeforeUPEXEMPLARY;
DELIMITER $

CREATE TRIGGER BeforeUPEXEMPLARY
BEFORE UPDATE ON EXEMPLARY FOR EACH ROW
	BEGIN
	DECLARE error CONDITION FOR SQLSTATE '99999';
	DECLARE AV VARCHAR(5);
	SELECT Available INTO AV FROM EXEMPLARY WHERE Code = NEW.Code;
	IF AV LIKE NEW.Available THEN
					SIGNAL error SET MESSAGE_TEXT = 'Este exemplar já se encontra neste estado';
	END IF;

END $

DELIMITER ;

*/
DROP TRIGGER IF EXISTS BeforeUPBOOK;
DELIMITER $

CREATE TRIGGER BeforeUPBOOK
BEFORE INSERT ON BOOK FOR EACH ROW
	BEGIN
		DECLARE BOOKS BOOL;
		DECLARE error CONDITION FOR SQLSTATE '99999';
		SET BOOKS = FALSE;
		SELECT TRUE INTO BOOKS FROM BOOK WHERE ISBN = NEW.ISBN;
		IF BOOKS THEN
						SIGNAL error SET MESSAGE_TEXT = 'Este Livro já está registado';
		END IF;
	END $

DELIMITER ;



CREATE TABLE IF NOT EXISTS ADD_BOOK
(
	StaffId INT NOT NULL,
	Code INT NOT NULL,
  Add_Day DATE NOT NULL,
 	PRIMARY KEY (StaffId,Code),
  FOREIGN KEY (StaffId) REFERENCES STAFF(StaffId) ON UPDATE CASCADE,
  FOREIGN KEY (Code) REFERENCES EXEMPLARY(Code) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS RENT
(
	Start_Date DATE NOT NULL,
	End_Date DATE DEFAULT NULL,
	StaffId INT NOT NULL,
	RentId INT AUTO_INCREMENT,
	ClientId INT NOT NULL,
	Fine DECIMAL(4,2),
  Code INT NOT NULL,
	ISBN INT NOT NULL,
	PRIMARY KEY (RentId),
	FOREIGN KEY (ISBN) REFERENCES BOOK(ISBN),
  FOREIGN KEY (ClientId) REFERENCES CLIENT(Client_Id) ON UPDATE CASCADE,
	FOREIGN KEY (Code) REFERENCES EXEMPLARY(Code) ON UPDATE CASCADE,
	FOREIGN KEY (StaffId) REFERENCES STAFF(StaffId) ON UPDATE CASCADE
);

DROP TRIGGER IF EXISTS AfterAddRENT;
DELIMITER $

CREATE TRIGGER AfterAddRENT
AFTER INSERT ON RENT FOR EACH ROW
BEGIN
	IF NEW.End_Date = NULL THEN
		UPDATE EXEMPLARY SET Available = 'False' WHERE Code = NEW.Code;
	END IF;

	IF NEW.End_Date <> NULL THEN
		UPDATE EXEMPLARY SET Available = 'True' WHERE Code = NEW.Code;
	END IF;
	UPDATE BOOK SET N_Available = getBooks(NEW.ISBN) WHERE ISBN = NEW.ISBN;
END $

DELIMITER ;





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


DROP FUNCTION IF EXISTS fine;
DELIMITER $

CREATE FUNCTION fine(Start_Date DATE,End_Date DATE)
RETURNS DECIMAL(4,2)
BEGIN
	 DECLARE Fine DECIMAL(4,2);
	 DECLARE DIASDECORRIDOS INT;
	 SET Fine = 0.00;
	 IF End_Date IS NULL THEN
	 		-- SET End_Date = CURDATE();
			SELECT DATEDIFF(CURDATE(),Start_Date) INTO DIASDECORRIDOS; -- FUNÇAO
			-- DATE A DAR VALOR 500 OU SEJA VALOR ERRADO
			IF DIASDECORRIDOS >= 15 THEN
			  SET Fine = 1.0 + 0.15 * DIASDECORRIDOS;
			  IF DIASDECORRIDOS >= 30 THEN
			    SET Fine = Fine * 1.5;
			    IF DIASDECORRIDOS >= 40 THEN
			      SET Fine = Fine * 1.75;
			    END IF;
			  END IF;
	    END IF;
	END IF;

	RETURN Fine;
END $

DELIMITER ;


DROP FUNCTION IF EXISTS getBooks;
DELIMITER $

CREATE FUNCTION getBooks(ISBNS INT)
RETURNS INT
BEGIN
  DECLARE n INT;
	SELECT count(*) from EXEMPLARY where ISBN LIKE ISBNS AND Available = 'True' INTO n;
  RETURN n;
END $
DELIMITER ;

DROP PROCEDURE IF EXISTS AddBook;
DELIMITER $



INSERT INTO
			BOOK(Title,Edition,N_Available,ISBN)
VALUES
			('Dois Amores',' 3 edição',@getBooks,124578921),('Azul e Branco','2 edição',@getBooks,123456789),
			('Dois Dragoes',' 2 edição',@getBooks,124578924),('Porto.','2 edição',@getBooks,123445841),
			('Bola na Barra',' 1 edição',@getBooks,12997892),('Portugal e a Europa','2 edição',@getBooks,453456789),
			('O Jornalismo',' 1 edição',@getBooks,12488892),('O Fim dos nossos Tempos','4 edição',@getBooks,145456789);

CREATE PROCEDURE AddEXEMPLARY
(IN Location_Shelf VARCHAR(15),
IN Location_Stand VARCHAR(15),IN ISBN INT,IN Available VARCHAR(5),
OUT N_Available INT)

BEGIN
	DECLARE n INT;
	SET n = getBooks(ISBN);
	UPDATE BOOK SET N_Available = n WHERE ISBN = ISBN;
	INSERT INTO
				EXEMPLARY(Location_Shelf,Location_Stand,ISBN,Available,DateIn)
	VALUES
				(Location_Shelf,Location_Stand,ISBN,Available,CURDATE());
END $
DELIMITER ;


DROP PROCEDURE IF EXISTS AgeCalc;
DELIMITER $
CREATE PROCEDURE AgeCalc
(IN Name VARCHAR(128),IN Active VARCHAR(5), IN Email VARCHAR(50),
IN Country VARCHAR(30), IN Address_Flor VARCHAR(12),IN Address_Street VARCHAR(128) ,
IN Address_City VARCHAR(30), IN Address_DoorN INT , IN Sex ENUM('M', 'F') , IN BirthDate DATE,IN Phone INT,
 OUT Age INT,OUT client_Id INT)
BEGIN
  -- Obtém valor a cobrar usando função
  SET Age = getAge(BirthDate);

  -- Insere registo na tabela CLIENT.
  INSERT INTO
				CLIENT(Name,Active,Email,Country,Address_Flor,Address_City,Address_Street,Address_DoorN,Sex,BirthDate,Age)
  VALUES (Name,active,Email,Country,Address_Flor,Address_City,Address_Street,Address_DoorN,Sex,BirthDate,Age);


	-- Obtém id de registo inserido (função LAST_INSERT_ID)
  SET client_Id = LAST_INSERT_ID();

	INSERT INTO
	       PHONE(Client_Id,Phone)
	VALUES
				(client_Id,Phone);


END $
DELIMITER ;

CALL AgeCalc('Pedro Pires','Yes','pedro1245@gmail.com','Portugal',NULL,'Porto','Avenida dos Aliados','1','M','1998-11-23',912458454,@Age,@client_Id);
CALL AgeCalc('Luis Miguel','NO','lm23@gmail.com','Portugal',NULL,'Porto','Avenida dos Aliados','1','M','1999-12-3',963850741,@Age,@client_Id);
CALL AgeCalc('Rui Pedro','NO','rp4894@gmail.com','Portugal',NULL,'Porto','Praça do Penta','1','M','1990-10-3',963450741,@Age,@client_Id);
CALL AgeCalc('Luis Pinto','NO','lm23@gmail.com','Portugal',NULL,'Porto','Rua das Igrejas','1','M','1999-12-3',967850741,@Age,@client_Id);
CALL AgeCalc('Luisa Soares','YES','aaasad23@gmail.com','Portugal',NULL,'Porto','Avenida dos Pontos','1','F','1999-10-3',963814741,@Age,@client_Id);
CALL AgeCalc('João Pinto','NO','jp2458@gmail.com','Portugal',NULL,'Porto','Rua das lamentações ','1','M','1990-2-3',963854541,@Age,@client_Id);
CALL AgeCalc('Sergio Conceição','YES','penta28@gmail.com','Portugal',NULL,'Porto','Avenida Dragão','1','F','2000-1-29',963878741,@Age,@client_Id);


DROP PROCEDURE IF EXISTS InsertRent;
DELIMITER $
CREATE PROCEDURE InsertRent
(IN Start_Date DATE,IN End_Date DATE,IN StaffId INT,
IN clientId INT,IN Code INT, IN ISBN INT,
 OUT Fine DECIMAL(4,2))
BEGIN
  SET Fine = fine(Start_Date,End_Date);
  INSERT INTO
				RENT(Start_Date,End_Date,StaffId,ClientId,Fine,Code,ISBN)
  VALUES (Start_Date,End_Date,StaffId,clientId,Fine,Code,ISBN);
END $
DELIMITER ;


INSERT INTO
			STAFF(SupervisorId,Job,Name)
VALUES
			(NULL,'Atendimento','José'),(1,'Director','Rui Pires');



CALL AddEXEMPLARY('estante 34','partleira 45',124578921,'True',@getBooks);
CALL AddEXEMPLARY('estante 4','partleira 45',123456789,'True',@getBooks);
CALL AddEXEMPLARY('estante 4','partleira 45',124578924,'True',@getBooks);
CALL AddEXEMPLARY('estante 4','partleira 45',123445841,'False',@getBooks);


CALL InsertRent('2020-03-01',NULL,1,1,2,123456789,@Fine);
CALL InsertRent('2020-01-01',NULL,1,2,3,124578924,@Fine);
CALL InsertRent('2020-01-05','2020-05-01',1,1,4,123445841,@Fine);
CALL InsertRent('2020-05-01','2020-05-11',1,2,1,123456789,@Fine);
CALL InsertRent('2020-07-06',NULL,1,1,3,124578924,@Fine);
CALL InsertRent('2020-10-11','2019-07-06',1,2,3,124578924,@Fine);


/*
INSERT INTO
			EXEMPLARY(Location_Shelf,Location_Stand,ISBN,Available)
VALUES
			('estante 12','partleira 22',12457892,'NO');*/




/*
INSERT INTO
			RENT(Start_Date,End_Date,StaffId,ClientId,Code)
VALUES
			('1998-01-01',NULL,1,1,1);*/
