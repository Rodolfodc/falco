--[[
   Compile and install digwatch rules.

   This module exports functions that are called from digwatch c++-side to compile and install a set of rules.

--]]

local compiler = require "compiler"

local function install_filter(node)
   local t = node.type

   if t == "BinaryBoolOp" then
      filter.nest() --io.write("(")
      install_filter(node.left)
      filter.bool_op(node.operator) --io.write(" "..node.operator.." ")
      install_filter(node.right)
      filter.unnest() --io.write(")")

   elseif t == "UnaryBoolOp" then
      filter.nest() --io.write("(")
      filter.bool_op(node.operator) -- io.write(" "..node.operator.." ")
      install_filter(node.argument)
      filter.unnest() -- io.write(")")

   elseif t == "BinaryRelOp" then
      filter.rel_expr(node.left.value, node.operator, node.right.value)
      -- io.write(node.left.value.." "..node.operator.." "..node.right.value)

   elseif t == "UnaryRelOp"  then
      filter.rel_expr(node.argument.value, node.operator)
      --io.write(node.argument.value.." "..node.operator)

   else
      error ("Unexpected type: "..t)
   end
end


-- filter.rel_expr("proc.name",  "=", "cat")
-- filter.bool_op("and")
-- filter.nest()
-- filter.nest()
-- filter.rel_expr("fd.num",  "=", "1")
-- filter.bool_op("or")
-- filter.rel_expr("fd.num",  "=", "2")
-- filter.unnest()
-- filter.unnest()

local state


function load_rule(r)
   if (state == nil) then
      state = compiler.init()
   end
   compiler.compile_line(r, state)
end

function on_done()
   install_filter(state.filter_ast)
end
