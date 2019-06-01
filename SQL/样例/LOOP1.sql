CREATE DEFINER=`root`@`%` PROCEDURE `loadlab`()
BEGIN

	DECLARE labname VARCHAR(20);
	DECLARE location VARCHAR(20);
	DECLARE done INT DEFAULT(0);
	DECLARE building VARCHAR(10);
	DECLARE floor VARCHAR(10);
	DECLARE room VARCHAR(10);
	DECLARE cur CURSOR FOR SELECT DISTINCT equipment_use_unit,equipment_location
		FROM equipment_lab WHERE equipment_location LIKE '第%' ORDER BY equipment_location;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;
	
	OPEN cur;
		
		myloop:LOOP
				-- 如果done等于1，跳出循环
				IF done = 1 THEN
					LEAVE myloop;
				END IF;
				-- 取一条数据
				FETCH cur INTO labname,location;
				-- 获取lab地址
				CALL changelocation(location,building,floor,room);
				-- 判断重复插入
				IF (SELECT COUNT(*) FROM lab 
				WHERE lab_building = building AND lab_floor = floor AND lab_room = room) = 0 THEN
					INSERT INTO lab(lab_name,lab_building,lab_floor,lab_room)
					VALUES(labname,building,floor,room);
				END IF;
				
	  END LOOP myloop;
		
	CLOSE cur;

END