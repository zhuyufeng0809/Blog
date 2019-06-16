/*
编写一个 SQL 查询，查找所有至少连续出现三次的数字。
+----+-----+
| Id | Num |
+----+-----+
| 1  |  1  |
| 2  |  1  |
| 3  |  1  |
| 4  |  2  |
| 5  |  1  |
| 6  |  2  |
| 7  |  2  |
+----+-----+

Create table If Not Exists Logs (Id int, Num int)
Truncate table Logs
insert into Logs (Id, Num) values ('1', '1')
insert into Logs (Id, Num) values ('2', '1')
insert into Logs (Id, Num) values ('3', '1')
insert into Logs (Id, Num) values ('4', '2')
insert into Logs (Id, Num) values ('5', '1')
insert into Logs (Id, Num) values ('6', '2')
insert into Logs (Id, Num) values ('7', '2')
*/

declare
  first int;
  second int;
  third int;
  target int;
begin

  target := -99;

  for i in (select ID from LOGS where ID >= 3) loop

    select NUM into third from LOGS where ID = i.ID;
    select NUM into second from LOGS where ID = i.ID - 1;
    select NUM into first from LOGS where ID = i.ID - 2;

    if first = second and second = third then
      if first <> target then
        target := first;
        dbms_output.put_line(target);
      end if;
    end if;

  end loop;

end;
