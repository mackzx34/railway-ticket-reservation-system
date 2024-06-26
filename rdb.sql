-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 03, 2024 at 09:12 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `rdb`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `assign_berth` (IN `tnum` INT, IN `tdate` DATE, IN `tcoach` VARCHAR(50), IN `name` VARCHAR(50), IN `age` INT, IN `gender` VARCHAR(50), IN `pnr_no` VARCHAR(12))  NO SQL BEGIN
	DECLARE bseats INT;
    DECLARE tseats INT;
    DECLARE berth_no INT;
    DECLARE coach_no INT;
    DECLARE berth_type VARCHAR(10);
    DECLARE msg varchar(250) DEFAULT '';
    
     -- update
    IF tcoach like 'ac' THEN
        UPDATE train_status
        SET seats_b_ac = seats_b_ac + 1
        WHERE t_number = tnum AND t_date = tdate;
    ELSE
        UPDATE train_status
        SET seats_b_sleeper = seats_b_sleeper + 1
        WHERE t_number = tnum AND t_date = tdate;
    END IF;
    IF tcoach like 'ac' THEN
        SET tseats = 18;
        SELECT seats_b_ac
        FROM train_status 
        WHERE t_number = tnum AND t_date = tdate
        INTO bseats;
    ELSE 
        SET tseats = 24;
        SELECT seats_b_sleeper
        FROM train_status
        WHERE t_number = tnum AND t_date = tdate
        INTO bseats;
    END IF;
    
    -- berth_no & coach_no
    IF bseats % tseats = 0 THEN
        SET coach_no = bseats/tseats;
        SET berth_no = tseats;
    ELSE
        SET coach_no = floor(bseats/tseats) + 1;
        SET berth_no = bseats%tseats;
    END IF;
	
    -- berth_type
    IF tcoach like 'ac' THEN
    	CASE berth_no % 6
            WHEN 1 THEN
               SET berth_type = 'LB';
            WHEN 2 THEN
               SET berth_type = 'LB';
            WHEN 3 THEN
               SET berth_type = 'UB';
            WHEN 4 THEN
               SET berth_type = 'UB';
            WHEN 5 THEN
               SET berth_type = 'SL';
            WHEN 0 THEN
               SET berth_type = 'SU';
		END CASE;
    ELSE
    	CASE berth_no % 8
            WHEN 1 THEN
               SET berth_type = 'LB';
            WHEN 2 THEN
               SET berth_type = 'MB';
            WHEN 3 THEN
               SET berth_type = 'UB';
            WHEN 4 THEN
               SET berth_type = 'LB';
            WHEN 5 THEN
               SET berth_type = 'MB';
            WHEN 6 THEN
               SET berth_type = 'UB';
            WHEN 7 THEN
               SET berth_type = 'SL';
            WHEN 0 THEN
               SET berth_type = 'SU';
		END CASE;
    END IF;
   
    -- insert
    INSERT INTO passenger 
    VALUES(name, age, gender, pnr_no, berth_no, berth_type, coach_no);
    
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_admin_credentials` (IN `n` VARCHAR(10), IN `p` VARCHAR(50))  NO SQL BEGIN
	DECLARE name VARCHAR(10);
	DECLARE pass VARCHAR(50);
    DECLARE message VARCHAR(128) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
	DEClARE user_info CURSOR
    	FOR SELECT * FROM admin;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    OPEN user_info;

	get_info: LOOP
		FETCH user_info INTO name, pass;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF name = n AND pass = p THEN
        	SET message = 'Found';
        END IF;
 
	END LOOP get_info;
	CLOSE user_info;
    
    IF message like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Invalid Username or Password';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_email_registered` (IN `in_email` VARCHAR(50))  NO SQL BEGIN
	DECLARE email_id VARCHAR(50);
    DECLARE message VARCHAR(128) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
	DEClARE user_email CURSOR
    	FOR SELECT email FROM user;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    OPEN user_email;

	get_email: LOOP
		FETCH user_email INTO email_id;
		IF finished = 1 THEN 
			LEAVE get_email;
		END IF;
        IF email_id = in_email THEN
        	SET message = 'Email id already registered';
        END IF;
 
	END LOOP get_email;
	CLOSE user_email;
    
    IF message != '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_seats_availabilty` (IN `tnum` INT, IN `tdate` DATE, IN `type` VARCHAR(50), IN `num_p` INT)  NO SQL BEGIN
	DECLARE avail_a INT;
    DECLARE avail_s INT;
    DECLARE book_a INT;
    DECLARE book_s INT;
    DECLARE m1 VARCHAR(128) DEFAULT '';
    DECLARE m2 VARCHAR(128) DEFAULT '';
  
    SELECT num_ac, num_sleeper
    FROM train
    WHERE t_number = tnum AND t_date = tdate
    INTO avail_a, avail_s;
    
    SELECT seats_b_ac, seats_b_sleeper
    FROM train_status
    WHERE t_number = tnum AND t_date = tdate
    INTO book_a, book_s;
    
    IF type like 'ac' THEN
    	IF avail_a = 0 THEN
        	SET m1 = CONCAT('No AC Coach is available in Train- ', tnum, ' Dated- ', tdate);
        ELSEIF avail_a*18 = book_a THEN
        	SET m1 = CONCAT('AC Coaches of Train- ', tnum, ' Dated- ', tdate, ' are already booked!');
        ELSEIF avail_a*18 < book_a + num_p THEN
        	SET m1 = CONCAT('AC Coach of Train- ', tnum, ' Dated- ', tdate, ' has only ' , avail_a*18-book_a, ' seats available!'); 
        END IF;
    ELSEIF type like 'sleeper' THEN
    	IF avail_s = 0 THEN
        	SET m1 = CONCAT('No Sleeper Coach is available in Train- ', tnum, ' Dated- ', tdate);
        ELSEIF avail_s*24 = book_s THEN
        	SET m1 = CONCAT('Sleeper Coaches of Train- ', tnum, ' Dated- ', tdate, ' are already booked!');
        ELSEIF avail_s*24 < book_s + num_p THEN
        	SET m1 = CONCAT('Sleeper Coach of Train- ', tnum, ' Dated- ', tdate, ' has only ' , avail_s*24-book_s, ' seats available!'); 
        END IF;
    END IF;
    
    IF m1 not like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = m1;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_train_details` (IN `num` INT(11), IN `date` DATE)  NO SQL BEGIN
	DECLARE n INT;
	DECLARE d DATE;
    DECLARE m1 VARCHAR(128) DEFAULT '';
    DECLARE m2 VARCHAR(128) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
    DECLARE upper_bound DATE DEFAULT DATE_ADD(CURRENT_DATE(), INTERVAL 2 MONTH);
	DEClARE train_info CURSOR
    	FOR SELECT t_number, t_date FROM train;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
    
    IF date < CURRENT_DATE() THEN
    	SET m1 = 'Please enter valid date';
    ELSEIF date > upper_bound THEN
    	SET m1 = 'Train can be booked atmost 2 months in advance';
    END IF;
    
    OPEN train_info;

	get_info: LOOP
		FETCH train_info INTO n, d;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF num = n AND date = d THEN
        	SET m2 = 'Found';
        END IF;
 
	END LOOP get_info;
	CLOSE train_info;
    
    IF m1 not like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = m1;
    ELSEIF m2 like '' THEN
    	SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Train not yet released!';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_username_registered` (IN `in_username` VARCHAR(10))  NO SQL BEGIN
	DECLARE name VARCHAR(10);
    DECLARE message VARCHAR(128) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
	DEClARE user_name CURSOR
    	FOR SELECT username FROM user;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    OPEN user_name;

	get_name: LOOP
		FETCH user_name INTO name;
		IF finished = 1 THEN 
			LEAVE get_name;
		END IF;
        IF name = in_username THEN
        	SET message = 'Username already taken';
        END IF;
 
	END LOOP get_name;
	CLOSE user_name;
    
    IF message != '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = message;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_user_credentials` (IN `n` VARCHAR(10), IN `p` VARCHAR(50))  NO SQL BEGIN
	DECLARE name VARCHAR(10);
	DECLARE pass VARCHAR(50);
    DECLARE message VARCHAR(128) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
	DEClARE user_info CURSOR
    	FOR SELECT username, password FROM user;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    OPEN user_info;

	get_info: LOOP
		FETCH user_info INTO name, pass;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF name = n AND pass = p THEN
        	SET message = 'Found';
        END IF;
 
	END LOOP get_info;
	CLOSE user_info;
    
    IF message like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Invalid Username or Password';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `check_valid_pnr` (IN `pnr` VARCHAR(12))  NO SQL BEGIN
	DECLARE msg VARCHAR(255) DEFAULT '';
    DECLARE p VARCHAR(12);
	DECLARE finished INT DEFAULT 0;
	DEClARE ticket_info CURSOR
    	FOR SELECT pnr_no FROM ticket;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    OPEN ticket_info;
	get_info: LOOP
		FETCH ticket_info INTO p;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF p like pnr THEN
        	SET msg = 'Found';
        END IF;
	END LOOP get_info;
	CLOSE ticket_info;
    
    IF msg like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'Please enter vaild PNR Number';
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `generate_pnr` (IN `u_name` VARCHAR(50), OUT `pnr_no` VARCHAR(12), IN `coach` VARCHAR(50), IN `t_number` INT, IN `t_date` DATE)  NO SQL BEGIN
	DECLARE p1 INT;
    DECLARE p2 INT;
    DECLARE p3 INT;
    SET p1 = LPAD(cast(conv(substring(md5(u_name), 1, 16), 16, 10)%1000 as unsigned integer), 3, '0');
    SET p2 = LPAD(FLOOR(RAND() * 999999.99), 3, '0');
    SET p3 = LPAD(cast(conv(substring(md5(CURRENT_TIMESTAMP()), 1, 16), 16, 10)%10000 as unsigned integer), 4, '0');
    SET pnr_no = RPAD(CONCAT(p1, '-', p2, '-', p3), 12, '0');
 	INSERT INTO ticket
    VALUES(pnr_no, coach, u_name, CURRENT_TIMESTAMP(), t_number, t_date);
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `admin`
--

CREATE TABLE `admin` (
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `admin`
--

INSERT INTO `admin` (`username`, `password`) VALUES
('admin', '7488e331b8b64e5794da3fa4eb10ad5d'),
('admin1', 'e00cf25ad42683b3df678c61f42c6bda');

-- --------------------------------------------------------

--
-- Table structure for table `passenger`
--

CREATE TABLE `passenger` (
  `name` varchar(50) NOT NULL,
  `age` int(11) NOT NULL,
  `gender` varchar(50) NOT NULL,
  `pnr_no` varchar(12) NOT NULL,
  `berth_no` int(11) NOT NULL,
  `berth_type` varchar(10) NOT NULL,
  `coach_no` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `passenger`
--

INSERT INTO `passenger` (`name`, `age`, `gender`, `pnr_no`, `berth_no`, `berth_type`, `coach_no`) VALUES
('Mjaliwa Mr', 25, 'Male', '696-276-5920', 1, 'LB', 1),
('Caren ', 23, 'Female', '696-276-5920', 2, 'LB', 1),
('Joseph Zacharia', 25, 'Male', '8-894-438400', 1, 'LB', 1);

--
-- Triggers `passenger`
--
DELIMITER $$
CREATE TRIGGER `before_berth_assign` BEFORE INSERT ON `passenger` FOR EACH ROW BEGIN
    DECLARE msg VARCHAR(255) DEFAULT '';
    DECLARE finished INT DEFAULT 0;
    DECLARE tnum INT;
    DECLARE tdate DATE;
    DECLARE c1 VARCHAR(50);
    DECLARE bno INT;
    DECLARE cno INT;
    DECLARE t_no INT;
    DECLARE t_d INT;
    DECLARE c2 VARCHAR(50);
	DECLARE p_info CURSOR FOR
        SELECT t_number, t_date, berth_no, coach_no, coach
        FROM passenger, ticket
        WHERE passenger.pnr_no = ticket.pnr_no;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;
        
    SELECT t_number, t_date, coach 
    FROM ticket
    WHERE pnr_no = NEW.pnr_no
    INTO t_no, t_d, c1;
    
    OPEN p_info;
	get_info: LOOP
		FETCH p_info INTO tnum, tdate, bno, cno, c2;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF tnum = t_no AND tdate = t_d AND bno = NEW.berth_no AND cno = NEW.coach_no AND c1 = c2 THEN
        	SET msg = 'Found';
        END IF;
	END LOOP get_info;
	CLOSE p_info;
    
    IF msg not like '' THEN
		SIGNAL SQLSTATE '45000'
    	SET MESSAGE_TEXT = 'This seat has been booked already';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `ticket`
--

CREATE TABLE `ticket` (
  `pnr_no` varchar(12) NOT NULL,
  `coach` varchar(50) NOT NULL,
  `booked_by` varchar(50) NOT NULL,
  `booked_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `t_number` int(11) NOT NULL,
  `t_date` date NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `ticket`
--

INSERT INTO `ticket` (`pnr_no`, `coach`, `booked_by`, `booked_at`, `t_number`, `t_date`) VALUES
('696-276-5920', 'ac', 'majaliwa', '2024-06-01 15:02:33', 1122, '2024-07-01'),
('8-894-438400', 'ac', 'joe', '2024-05-23 13:35:32', 1, '2024-06-23');

--
-- Triggers `ticket`
--
DELIMITER $$
CREATE TRIGGER `check_ticket_update` BEFORE UPDATE ON `ticket` FOR EACH ROW BEGIN
	IF NEW.pnr_no != OLD.pnr_no OR NEW.coach != OLD.coach THEN
    	SIGNAL SQLSTATE '45000' 
    	SET MESSAGE_TEXT = 'Ticket details cannot be updated';
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `train`
--

CREATE TABLE `train` (
  `t_number` int(11) NOT NULL,
  `t_date` date NOT NULL,
  `num_ac` int(11) NOT NULL,
  `num_sleeper` int(11) NOT NULL,
  `released_by` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `train`
--

INSERT INTO `train` (`t_number`, `t_date`, `num_ac`, `num_sleeper`, `released_by`) VALUES
(1, '2024-06-23', 10, 10, 'admin'),
(1122, '2024-07-01', 10, 10, 'admin');

--
-- Triggers `train`
--
DELIMITER $$
CREATE TRIGGER `before_train_release` BEFORE INSERT ON `train` FOR EACH ROW BEGIN
    DECLARE message VARCHAR(128) DEFAULT '';
    DECLARE train_number INT;
    DECLARE train_date DATE;
    DECLARE lower_bound DATE DEFAULT DATE_ADD(CURRENT_DATE(), INTERVAL 1 MONTH);
    DECLARE upper_bound DATE DEFAULT DATE_ADD(CURRENT_DATE(), INTERVAL 4 MONTH);
    DECLARE finished INT DEFAULT 0;
    DEClARE train_info CURSOR
    	FOR SELECT t_number, t_date FROM train;
	DECLARE CONTINUE HANDLER 
    	FOR NOT FOUND SET finished = 1;

    IF NEW.t_date < CURRENT_DATE() THEN
    	SET message = CONCAT('Please select a date between ', lower_bound, ' and ', upper_bound);
    ELSEIF NEW.t_date < lower_bound THEN
    	SET message = CONCAT('It is too late for a train to be released! You are ', DATEDIFF(lower_bound, NEW.t_date), ' days late.' );
    ELSEIF NEW.t_date > upper_bound THEN
    	SET message = CONCAT('It is too early for the train to be released! Try Again after ', DATEDIFF(NEW.t_date, upper_bound), ' Days');
    END IF;
    
    IF message != '' THEN
        SIGNAL SQLSTATE '45000' 
    	SET MESSAGE_TEXT = message;
    END IF;

    IF NEW.num_ac < 0 OR NEW.num_sleeper < 0 THEN
    SET message = (message, CHAR(13), 'Enter valid number of coaches');
    ELSEIF NEW.num_ac + NEW.num_sleeper = 0 THEN
    SET message = CONCAT(message, CHAR(13), 'There is no coach in the train');
    END IF;

    IF message != '' THEN
        SIGNAL SQLSTATE '45000' 
    	SET MESSAGE_TEXT = message;
    END IF;
    
	OPEN train_info;

	get_info: LOOP
		FETCH train_info INTO train_number, train_date;
		IF finished = 1 THEN 
			LEAVE get_info;
		END IF;
        IF train_number = NEW.t_number AND
           train_date = NEW.t_date THEN
        	SET message = CONCAT(message, '\nTrain number ', NEW.t_number, ' has been already released for ', NEW.t_date);
        END IF;
 
	END LOOP get_info;
   
	CLOSE train_info;

    IF message != '' THEN
    	SIGNAL SQLSTATE '45000' 
    	SET MESSAGE_TEXT = message;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `train_status`
--

CREATE TABLE `train_status` (
  `t_number` int(11) NOT NULL,
  `t_date` date NOT NULL,
  `seats_b_ac` int(11) NOT NULL,
  `seats_b_sleeper` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `train_status`
--

INSERT INTO `train_status` (`t_number`, `t_date`, `seats_b_ac`, `seats_b_sleeper`) VALUES
(1, '2024-06-23', 1, 0),
(1122, '2024-07-01', 2, 0);

--
-- Triggers `train_status`
--
DELIMITER $$
CREATE TRIGGER `check_booked_seats` BEFORE UPDATE ON `train_status` FOR EACH ROW BEGIN
	DECLARE msg varchar(255) DEFAULT '';
    DECLARE avail_a INT;
    DECLARE avail_s INT;
    
    SELECT num_ac, num_sleeper
    FROM train
    WHERE t_number = OLD.t_number AND t_date = OLD.t_date
    INTO avail_a, avail_s;
    
	IF NEW.seats_b_ac > avail_a*18 THEN
    	SET msg = CONCAT(msg, ' Sufficient Seats are not available in AC Coach of Train no ', NEW.t_number, ' Dated ', NEW.t_date);
    END IF;
    IF NEW.seats_b_sleeper > avail_s*24 THEN
    	SET msg = CONCAT(msg, ' Sufficient Seats are not available in Sleeper Coach of Train no ', NEW.t_number, ' Dated ', NEW.t_date);
    END IF;

    IF msg != '' THEN
    	SIGNAL SQLSTATE '45000' 
    	SET MESSAGE_TEXT = msg;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `username` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `address` varchar(128) NOT NULL,
  `password` varchar(50) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`username`, `name`, `email`, `address`, `password`) VALUES
('adminn', 'admin admin', 'admin11@gmail.com', 'kahama', '7488e331b8b64e5794da3fa4eb10ad5d'),
('dako', 'John Dako', 'dakojohn36@gmail.com', 'kahama', '$2y$10$L1x45AmST/9LuP0HhEv4uOqJXRZuUrQ7puQecR2QM/E'),
('fatuma', 'Fatuma Jadi', 'jadifatma45@gmail.com', 'Dar es salaam', '$2y$10$vgcGWjVYzWBQ1ypGumiq9OTvxeglG5fBR0gWm8Yw0OG'),
('fatumaa', 'Fatuma Jadi', 'jadifatma4rt5@gmail.com', 'Dar es salaam', '$2y$10$mdNm2F0.aKgGqZYCc8fXDu9eXBLyvi4QfWhj7hdXE4x'),
('halima', 'Halima', 'halima45@gmail.com', 'dar', 'halima12345'),
('joe', 'JOSEPH ZACHARIA ROJA', 'josephroja99@gmail.com', 'Dodoma', '200300400Ab'),
('kulwa', 'kulwa dato', 'kulwaje@gmail.com', 'jakka', '823fc4bf7a02b5b2b62c1eee4f5bceb1'),
('majaliwa', 'Majaliwa John', 'majaliwa365@gmail.com', 'Kigoma', 'a3b314b4eed9a847dfe27ce3cb560296'),
('musa', 'musa ally', 'musa26@yahoo.com', 'Dar', '7dbaf4d3bce3b62558e6831d59c08eb3');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`username`);

--
-- Indexes for table `passenger`
--
ALTER TABLE `passenger`
  ADD PRIMARY KEY (`pnr_no`,`berth_no`,`coach_no`),
  ADD KEY `pnr_no` (`pnr_no`);

--
-- Indexes for table `ticket`
--
ALTER TABLE `ticket`
  ADD PRIMARY KEY (`pnr_no`),
  ADD KEY `username` (`booked_by`),
  ADD KEY `t_number` (`t_number`,`t_date`);

--
-- Indexes for table `train`
--
ALTER TABLE `train`
  ADD PRIMARY KEY (`t_number`,`t_date`),
  ADD KEY `released_by` (`released_by`);

--
-- Indexes for table `train_status`
--
ALTER TABLE `train_status`
  ADD PRIMARY KEY (`t_number`,`t_date`),
  ADD KEY `t_number` (`t_number`),
  ADD KEY `t_date` (`t_date`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`username`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `passenger`
--
ALTER TABLE `passenger`
  ADD CONSTRAINT `passenger_ibfk_1` FOREIGN KEY (`pnr_no`) REFERENCES `ticket` (`pnr_no`);

--
-- Constraints for table `ticket`
--
ALTER TABLE `ticket`
  ADD CONSTRAINT `ticket_ibfk_1` FOREIGN KEY (`booked_by`) REFERENCES `user` (`username`),
  ADD CONSTRAINT `ticket_ibfk_2` FOREIGN KEY (`t_number`,`t_date`) REFERENCES `train` (`t_number`, `t_date`);

--
-- Constraints for table `train`
--
ALTER TABLE `train`
  ADD CONSTRAINT `train_ibfk_1` FOREIGN KEY (`released_by`) REFERENCES `admin` (`username`);

--
-- Constraints for table `train_status`
--
ALTER TABLE `train_status`
  ADD CONSTRAINT `train_status_ibfk_1` FOREIGN KEY (`t_number`,`t_date`) REFERENCES `train` (`t_number`, `t_date`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
