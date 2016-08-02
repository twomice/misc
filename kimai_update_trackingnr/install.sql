--
-- Table structure for table `update_trackingnr_auth_log`
--

DROP TABLE IF EXISTS `update_trackingnr_auth_log`;
CREATE TABLE IF NOT EXISTS `update_trackingnr_auth_log` (
  `authlog_ID` int(11) NOT NULL AUTO_INCREMENT,
  `timestamp` datetime NOT NULL,
  PRIMARY KEY (`authlog_ID`),
  KEY `timestamp` (`timestamp`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=34 ;

