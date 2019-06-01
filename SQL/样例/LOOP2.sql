CREATE DEFINER=`root`@`%` PROCEDURE `loadlabid`()
BEGIN

	DECLARE id INT;
	DECLARE location VARCHAR(20);
	DECLARE building INT;
	DECLARE floor INT;
	DECLARE room INT;
	DECLARE done INT DEFAULT(0);
	DECLARE cur CURSOR FOR SELECT lab_id,equipment_location FROM equipment_lab 
		WHERE equipment_location LIKE '第%';
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
	OPEN cur;
	
	myloop:LOOP
	
				IF done = 1 THEN
					LEAVE myloop;
				END IF;
				
				-- 取一条数据
				FETCH cur INTO id,location;
				-- 判断是否需要插入id
				IF id = 999999 THEN
					CALL changelocation(location, building, floor, room);
					SET id = (SELECT lab_id FROM lab 
						WHERE lab_building = building AND lab_floor = floor AND lab_room = room);
					UPDATE equipment_lab SET lab_id = id WHERE equipment_location = location;
				END IF;
				
	END LOOP myloop;
	
	CLOSE cur;
	
END