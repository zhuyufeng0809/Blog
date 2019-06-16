/*
	Employee 表包含所有员工，他们的经理也属于员工。
	每个员工都有一个 Id，此外还有一列对应员工的经理的 Id。

	+----+-------+--------+-----------+
	| Id | Name  | Salary | ManagerId |
	+----+-------+--------+-----------+
	| 1  | Joe   | 70000  | 3         |
	| 2  | Henry | 80000  | 4         |
	| 3  | Sam   | 60000  | NULL      |
	| 4  | Max   | 90000  | NULL      |
	+----+-------+--------+-----------+

	Create table If Not Exists Employee (Id int, Name varchar(255), Salary int, ManagerId int)
	Truncate table Employee
	insert into Employee (Id, Name, Salary, ManagerId) values ('1', 'Joe', '70000', '3')
	insert into Employee (Id, Name, Salary, ManagerId) values ('2', 'Henry', '80000', '4')
	insert into Employee (Id, Name, Salary, ManagerId) values ('3', 'Sam', '60000', 'None')
	insert into Employee (Id, Name, Salary, ManagerId) values ('4', 'Max', '90000', 'None')

*/

declare
  staff number;
  boss number;
begin
  for i in (select * from EMPLOYEE) loop
    if i.MANAGERID is not null then
      select SALARY into staff from EMPLOYEE where ID = i.ID;
      select SALARY into boss from EMPLOYEE where ID = i.MANAGERID;
      if staff > boss then
        dbms_output.put_line(i.NAME);
      end if;
    end if;
  end loop;
end;

