CREATE DEFINER=`root`@`%` PROCEDURE `changelocation`(
	IN location VARCHAR(20),
	OUT building INT,
	OUT floor INT,
	OUT room INT)
BEGIN
	DECLARE temp VARCHAR(10);
	IF 27 = LENGTH(location) THEN
					SET temp = SUBSTR(location,2,1);
				ELSE
					SET temp = SUBSTR(location,2,2);
				END IF;
	-- 转换成阿拉伯数字
	CASE temp
		WHEN '一' THEN
			SET building = 1;
		WHEN '二' THEN
			SET building = 2;
		WHEN '三' THEN
			SET building = 3;
		WHEN '四' THEN
			SET building = 4;
		WHEN '五' THEN
			SET building = 5;
		WHEN '六' THEN
			SET building = 6;
		WHEN '七' THEN
			SET building = 7;
		WHEN '八' THEN
			SET building = 8;
		WHEN '九' THEN
			SET building = 9;
		WHEN '十' THEN
			SET building = 10;
		WHEN '十一' THEN
			SET building = 11;
		WHEN '十二' THEN
			SET building = 12;
		ELSE
			SET building = 0;
		END CASE;
		-- 截取楼层
		SET floor = SUBSTR(location,-4,1);
		-- 截取门牌号
		SET room = SUBSTR(location,-4,3);
END