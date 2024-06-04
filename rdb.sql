-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Jun 05, 2024 at 12:31 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET FOREIGN_KEY_CHECKS=0;
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
CREATE DATABASE IF NOT EXISTS `rdb` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci;
USE `rdb`;

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
-- RELATIONSHIPS FOR TABLE `passenger`:
--   `pnr_no`
--       `ticket` -> `pnr_no`
--

--
-- Dumping data for table `passenger`
--

INSERT INTO `passenger` (`name`, `age`, `gender`, `pnr_no`, `berth_no`, `berth_type`, `coach_no`) VALUES
('ss', 23, 'Female', '504-560-1200', 9, 'UB', 2),
('ali', 43, 'Male', '504-889-3520', 10, 'UB', 2),
('mahoo', 35, 'Female', '504-889-3520', 11, 'SL', 2);

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
-- RELATIONSHIPS FOR TABLE `ticket`:
--

--
-- Dumping data for table `ticket`
--

INSERT INTO `ticket` (`pnr_no`, `coach`, `booked_by`, `booked_at`, `t_number`, `t_date`) VALUES
('504-115-6336', 'ac', 'jode', '2024-06-04 22:10:34', 1, '2024-06-23'),
('504-169-8592', 'ac', 'jode', '2024-06-04 22:10:31', 1, '2024-06-23'),
('504-257-6304', 'ac', 'jode', '2024-06-04 22:14:19', 1, '2024-06-23'),
('504-267-5504', 'ac', 'jode', '2024-06-04 22:10:40', 1, '2024-06-23'),
('504-293-3568', 'ac', 'jode', '2024-06-04 22:10:32', 1, '2024-06-23'),
('504-350-4496', 'ac', 'jode', '2024-06-04 22:10:35', 1, '2024-06-23'),
('504-437-6608', 'ac', 'jode', '2024-06-04 22:10:33', 1, '2024-06-23'),
('504-446-5360', 'ac', 'jode', '2024-06-04 22:10:29', 1, '2024-06-23'),
('504-454-6464', 'ac', 'jode', '2024-06-04 22:10:38', 1, '2024-06-23'),
('504-492-6880', 'ac', 'jode', '2024-06-04 22:10:39', 1, '2024-06-23'),
('504-560-1200', 'ac', 'jode', '2024-06-04 22:19:54', 1, '2024-06-23'),
('504-562-3408', 'ac', 'jode', '2024-06-04 22:19:05', 1, '2024-06-23'),
('504-618-8592', 'ac', 'jode', '2024-06-04 22:10:31', 1, '2024-06-23'),
('504-678-8160', 'ac', 'jode', '2024-06-04 22:10:26', 1, '2024-06-23'),
('504-693-1456', 'ac', 'jode', '2024-06-04 22:10:36', 1, '2024-06-23'),
('504-706-9504', 'ac', 'jode', '2024-06-04 22:10:30', 1, '2024-06-23'),
('504-736-8256', 'ac', 'jode', '2024-06-04 22:19:07', 1, '2024-06-23'),
('504-793-3920', 'ac', 'jode', '2024-06-04 22:10:24', 1, '2024-06-23'),
('504-826-3744', 'ac', 'jode', '2024-06-04 20:57:19', 1, '2024-06-23'),
('504-830-3632', 'ac', 'jode', '2024-06-04 20:56:00', 1, '2024-06-23'),
('504-878-8688', 'ac', 'jode', '2024-06-04 22:10:37', 1, '2024-06-23'),
('504-889-3520', 'ac', 'jode', '2024-06-04 22:22:00', 1, '2024-06-23'),
('504-910-2528', 'ac', 'jode', '2024-06-04 22:10:28', 1, '2024-06-23'),
('504-923-9312', 'ac', 'jode', '2024-06-04 22:09:50', 1, '2024-06-23'),
('504-924-9008', 'ac', 'jode', '2024-06-04 22:19:00', 1, '2024-06-23'),
('504-958-1456', 'ac', 'jode', '2024-06-04 22:10:36', 1, '2024-06-23'),
('504-965-1280', 'ac', 'jode', '2024-06-04 22:10:27', 1, '2024-06-23');

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
-- RELATIONSHIPS FOR TABLE `train`:
--

--
-- Dumping data for table `train`
--

INSERT INTO `train` (`t_number`, `t_date`, `num_ac`, `num_sleeper`, `released_by`) VALUES
(1, '2024-06-23', 10, 10, ''),
(23, '2024-06-08', 23, 23, 'admin'),
(124, '2024-06-06', 12, 12, 'admin'),
(234, '2024-06-07', 12, 12, 'admin'),
(234, '2024-06-08', 23, 23, 'admin'),
(243, '2024-06-07', 20, 20, 'admin'),
(453, '2024-06-08', 12, 12, 'admin'),
(777, '2024-07-05', 5, 5, 'admin'),
(1122, '2024-07-01', 10, 10, '');

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
-- RELATIONSHIPS FOR TABLE `train_status`:
--   `t_number`
--       `train` -> `t_number`
--   `t_date`
--       `train` -> `t_date`
--

--
-- Dumping data for table `train_status`
--

INSERT INTO `train_status` (`t_number`, `t_date`, `seats_b_ac`, `seats_b_sleeper`) VALUES
(1, '2024-06-23', 29, 0),
(234, '2024-06-07', 0, 0),
(243, '2024-06-07', 0, 0),
(453, '2024-06-08', 0, 0),
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
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `user` varchar(50) NOT NULL,
  `name` varchar(50) NOT NULL,
  `email` varchar(50) NOT NULL,
  `address` varchar(128) NOT NULL,
  `role` tinyint(1) NOT NULL DEFAULT 0,
  `password` varchar(50) NOT NULL,
  `token` text NOT NULL,
  `last_login` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `failed_login` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- RELATIONSHIPS FOR TABLE `users`:
--

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `user`, `name`, `email`, `address`, `role`, `password`, `token`, `last_login`, `failed_login`) VALUES
(1, 'admin', 'admin', 'admin@gmail.com', 'Dodoma', 1, '40bd001563085fc35165329ea1ff5c5ecbdbbeef', '', '2024-06-04 22:29:03', 0),
(2, 'deleter', 'deleter', 'deleter@gmail.com', 'Dodoma', 1, '40bd001563085fc35165329ea1ff5c5ecbdbbeef', '', '2024-06-04 22:26:34', 0),
(3, 'jj', 'ss', 'jadizo@gmail.com', 'ss', 0, '7c222fb2927d828af22f592134e8932480637c0d', '', '2024-06-04 04:47:54', 0),
(4, 'dele', 'Ismail Haji', 'dele@gmail.com', 'Dodoma', 0, '40bd001563085fc35165329ea1ff5c5ecbdbbeef', '', '2024-06-04 12:32:29', 0),
(5, 'jode', 'jadi', 'jose@gmail.com', 'hh', 0, '40bd001563085fc35165329ea1ff5c5ecbdbbeef', '', '2024-06-04 22:09:05', 0);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `passenger`
--
ALTER TABLE `passenger`
  ADD PRIMARY KEY (`pnr_no`,`berth_no`,`coach_no`);

--
-- Indexes for table `ticket`
--
ALTER TABLE `ticket`
  ADD PRIMARY KEY (`pnr_no`),
  ADD KEY `t_number` (`t_number`,`t_date`);

--
-- Indexes for table `train`
--
ALTER TABLE `train`
  ADD PRIMARY KEY (`t_number`,`t_date`);

--
-- Indexes for table `train_status`
--
ALTER TABLE `train_status`
  ADD PRIMARY KEY (`t_number`,`t_date`),
  ADD KEY `t_date` (`t_date`),
  ADD KEY `t_number` (`t_number`) USING BTREE;

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `passenger`
--
ALTER TABLE `passenger`
  ADD CONSTRAINT `passenger_ibfk_1` FOREIGN KEY (`pnr_no`) REFERENCES `ticket` (`pnr_no`);

--
-- Constraints for table `train_status`
--
ALTER TABLE `train_status`
  ADD CONSTRAINT `train_status_ibfk_1` FOREIGN KEY (`t_number`,`t_date`) REFERENCES `train` (`t_number`, `t_date`);
SET FOREIGN_KEY_CHECKS=1;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
