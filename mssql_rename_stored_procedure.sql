USE [<database>] -- filter the database here

set nocount on

declare @counter int = 1

declare @extension varchar(100) = '' -- add the extension name here (ex: _offline20250510) or whatever you designate here

declare @old_name varchar(500)

declare @new_name varchar(500) 

declare @object_names table
(this_object_name varchar(200))

declare @debug int = 0

insert @object_names 
(this_object_name)
select distinct name 
from sys.procedures 
where name in ('') -- filter the databases here 

declare csrSprocs cursor
local forward_only static read_only 
for select distinct this_object_name
from @object_names

open csrSprocs

	fetch next from csrSprocs into @old_name

	while @@FETCH_STATUS = 0
	begin	
		
		raiserror ('@counter: %d', 0, 1, @counter) with nowait 
		raiserror ('@old_name: %s', 0, 1, @old_name) with nowait 

		set @new_name = @old_name + @extension

		raiserror ('@new_name: %s', 0, 1, @new_name) with nowait 

		if @debug = 0
			begin -- @debug = 0
				exec sp_rename @old_name, @new_name
			end --@debug = 0
		
		raiserror ('==============================', 0, 1) with nowait

		set @counter = @counter + 1
		set @new_name = null

	fetch next from csrSprocs into @old_name
end
		
close csrSprocs
deallocate csrSprocs
