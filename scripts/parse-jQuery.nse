local http = require "http"
local httpspider = require "httpspider"
local stdnse = require "stdnse"
local string = require "string"
local table = require "table"
local shortport = require "shortport"


description = [[

	this script will parse a jQuery file and retrieves all function related to ajax,
	and extract the uri and it's parameters.
	
]]

author = "Abdelmouneim Hanine <sup3rnova.m0nster@gmail.com>"
categories = {"safe","discovery"}
--[[
	this the structure of the table that contains the links and it's parameters
	{
		{
			method = "POST",
			path = "/php/produit.php",
			params = {"id_produit","ajax_id_produit_sproduit"}	
		},
		{
			method = "GET",
			path = "/php/produit.php",
			params = {"id_produit","ajax_id_produit_sproduit"}	
		}
	
	}
	syntax of post method
		$(selector).post(URL,data,function(data,status,xhr),dataType)
		example:
		$.post("demo_ajax_gethint.asp", {suggest: txt}, function(result){
		    $("span").html(result);
		});
	syntax of get method
		$.get(URL,data,function(data,status,xhr),dataType)
		example:
		$.get("test.php", { name:"Donald", town:"Ducktown" });
	syntax of load method 
		$(selector).load(url,data,function(response,status,xhr))
		example:
		$("button").click( function(){ $("#div1").load("demo_test.txt"); } ); 
	syntax of ajax method
		$.ajax({name:value, name:value, ... })
		example:
		$.ajax({url: "demo_test.txt", success: function(result){
        $("#div1").html(result); }});

	get,post,load have the same syntax	
]]
portrule = shortport.http

function map(func, table)
	local result = {}
	for i,x in pairs(table) do
		result[i] = func(x)
	end
	return result
end



switch = {
			[1] = function (token) 
					local link = {} 
					local path = {}
					local method = {}
					local parameters = {}
					path ['name'] = "PATH"
					method ['name'] = "method"
					parameters['name'] = "parameters"
					table.insert(method,"POST")
					table.insert( path, token:match("%([\"'](.-)[\"']") )
					local params = ""
					params = token:match(",%s*{%s*(.-)%s*}%s*")
					if ( params ~= nil ) then
						for param, _ in params:gmatch("[%s]*,?(%S-)%s*:%s*(%S-)%s*,?") do 
							table.insert(parameters, param:match("%S+"))
						end
					end
					table.insert(link, path)
					table.insert(link, method)
					table.insert(link, parameters)
					return link
				  end,
			[2] = function (token) 
					local link = {} 
					local path = {}
					local method = {}
					local parameters = {}
					path ['name'] = "PATH"
					method ['name'] = "method"
					parameters['name'] = "parameters"
					table.insert(method,"POST")
					table.insert( path, token:match("%([\"'](.-)[\"']") )
					local params = ""
					params = token:match(",%s*{%s*(.-)%s*}%s*")
					if ( params ~= nil ) then
						for param, _ in params:gmatch("[%s]*,?(%S-)%s*:%s*(%S-)%s*,?") do 
							table.insert(parameters, param:match("%S+"))
						end
					end
					table.insert(link, path)
					table.insert(link, method)
					table.insert(link, parameters)
					return link
				  end,
			[3] = function (token)
					local link = {} 
					local path = {}
					local method = {}
					local parameters = {}
					path ['name'] = "PATH"
					method ['name'] = "method"
					parameters['name'] = "parameters"
					table.insert(method,"GET")
					table.insert(path, token:match("%([\"'](.-)[\"']") )
					local params = ""
					params = token:match(",%s*{%s*(.-)%s*}%s*")
					if ( params ~= nil ) then
						for param, _ in params:gmatch("[%s]*,?(%S-)%s*:%s*(%S-)%s*,?") do 
							table.insert(parameters, param:match("%S+"))
						end
					end
					table.insert(link, path)
					table.insert(link, method)
					table.insert(link, parameters)
					return link 
				  end,
			[4] = function (token) 
					local link = {} 
					local path = {}
					local method = {}
					local parameters = {}
					path ['name'] = "PATH"
					method ['name'] = "method"
					parameters['name'] = "parameters"
					table.insert(method, token:match("type%s*:%s*[\"'](.-)[\"']") )
					table.insert(path, token:match("url%s*:%s*[\"'](.-)[\"']") )
					local params = ""
					params = token:match("%s*,?%s*data%s*:%s*(.-)[,}]")
					if ( params ~= nil ) then
						for param in params:gmatch("&?%s*(.-)%s*=") do 
							table.insert(parameters, param:match("%s*['\"]?&?(%S+)$") )
						end
					end
					table.insert(link, path)
					table.insert(link, method)
					table.insert(link, parameters)
					return link
				   end,
 					}

action = function(host, port)
	local response = {}
	local patterns = {'%$%s*%(?%s*%S*%s*%)?%s*(%.load%s*%b())', --load
					  '%$%s*%(?%s*%S*%s*%)?%s*(%.post*%b())', --post
					  '%$%s*%(?%s*%S*%s*%)?%s*(%.get%b())', -- get
					  '%$%s*%(?%s*%S*%s*%)?%s*(%.ajax%b())' --ajax
					 } -- %b() captures anythings between () including them
	local links = {}
	local uri = stdnse.get_script_args(SCRIPT_NAME..'.uri') or "/"
	local crawler = httpspider.Crawler:new(host, port, uri, {scriptname = SCRIPT_NAME}) 
	while(true) do
    	local status, r = crawler:crawl()
		if (not(status)) then
			if (r.err) then
				return stdnse.format_output(true, "ERROR: %s", r.reason)
			else
				break
			end
		end
			-- local filename = stdnse.get_script_args(SCRIPT_NAME..".filename")
			-- local file = assert(io.open(filename))
			-- load the entire file into string a variable
		if (  crawler:isresource(r.url, "js") ) then 
			local contents = r.response.body  --file:read('*a')
			for i , pattern in ipairs(patterns) do
				for token in string.gmatch(contents,pattern) do 
					token = token:gsub("/%*.+%*/","") -- omit the multiple line comments
					token = token:gsub("//.-\n","\n") -- omit line comments
					local link = switch[i](token)
					link ['name'] = '-----------'..tostring(r.url)..'-----------'
					table.insert(links,link)
				end -- end for token
			end -- end for patterns	
		end -- if crawler
	end -- end while(true) 
	return stdnse.format_output(true, links)
end
