-- Import the TaskLine class
local task_line = require 'gtd.taskline'
local modify_line = require 'gtd.modifyline'

describe("TaskLine", function()
    describe("Check task completion", function()
        it("update fields", function()
            local line = "- [ ] (A) this is a task"
            local updated_line = modify_line.complete_task({}, line)
            local expected_line = "- [x] (A) this is a task | note:[[" .. os.date("%Y-%m-%d") .. "]]"
            assert.are.equal(expected_line, updated_line)
        end)
    end)

    describe("TaskLine", function()
        it("update fields", function()
            local task = task_line.from_string("- [x] (A) this is a task")
            assert.are.equal("x", task.status)
            assert.are.equal("A", task.priority)
            assert.are.equal("this is a task", task.text)

            task = task_line.update_fields(task, { status = " " })
            assert.are.equal(" ", task.status)
            assert.are.equal("A", task.priority)
            assert.are.equal("this is a task", task.text)

            local line = modify_line.update_task_line({ status = "x" }, "- [ ] this is a task")
            assert.are.equal("- [x] this is a task", line)
            assert.are.equal("this is a task", task.text)
        end)
    end)

    it("basic invalid string parses", function()
        local task = task_line.from_string("this is not a task")
        assert.is_false(task_line.is_valid(task))
        task = task_line.from_string("[ ] this is not a task")
        assert.is_false(task_line.is_valid(task))
        task = task_line.from_string(" - [ ] this is not a task")
        assert.is_false(task_line.is_valid(task))

        task = task_line.from_string("- [z] this is a task bla bla due:[2024-02-02]")
        assert.is_nil(task.due_date)

    end)

     it("basic valid string parses", function()
         local task = task_line.from_string("- [x] (A) this is a task")
         assert.are.equal("x", task.status)
         assert.are.equal("A", task.priority)
         assert.are.equal("this is a task", task.text)

         task = task_line.from_string("- [ ] (A) this is a task")
         assert.are.equal(" ", task.status)
         assert.are.equal("this is a task", task.text)

         task = task_line.from_string("- [ ] (A) this is a task | test")
         assert.are.equal(" ", task.status)
         assert.are.equal("this is a task", task.text)

         task = task_line.from_string("- [y] this is a task | test")
         assert.are.equal("y", task.status)
         assert.are.equal("this is a task", task.text)

         task = task_line.from_string("- [z] this is a task")
         assert.are.equal("z", task.status)
         assert.are.equal("this is a task", task.text)

         task = task_line.from_string("- [z] this is a task | bla bla due:[2024-02-02]")
         assert.are.equal("z", task.status)
         assert.are.equal("this is a task", task.text)
         assert.are.equal("2024-02-02", task.due_date)
     end)

     it("parses a string correctly", function()
         local input_str = "- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]"
         local task = task_line.from_string(input_str)
         assert.is_true(task_line.is_valid(task))
         assert.are.equal("x", task.status)
         assert.are.equal("A", task.priority)
         assert.are.equal("this is a completed task", task.text)
         assert.are.equal("2024-02-02", task.due_date)
         assert.are.equal("Sagi", task.assignee)
         assert.are.equal("2024-02-01", task.followup_date)
         assert.are.equal("2", task.again_num)
         assert.are.equal("d", task.again_period)
         assert.are.equal("2024-02-02][2024-02-02-Tasks-Notes.md", task.note)
     end)

    -- it("converts fields to a string correctly", function()
    --     local task = task_line.from_string("- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]")
    --     assert.is_true(task_line.is_valid(task))
    --     local fields = {
    --         due_date = true,
    --         assignee = true,
    --         followup_date = true,
    --         again_num = true,
    --         again_period = true,
    --         note = true
    --     }
    --     local output_str = task_line.to_string(fields)
    --     local expected_str = "- [x] this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]"
    --     assert.are.equal(expected_str, output_str)
    -- end)

    -- it("converts partial fields to a string correctly", function()
    --     local task = task_line.from_string("- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]")
    --     assert.is_true(task_line.is_valid(task))
    --     local fields = {
    --         due_date = true,
    --         priority = true,
    --         assignee = true,
    --         followup_date = true,
    --         note = true
    --     }
    --     local output_str = task_line.to_string(fields)
    --     local expected_str = "- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]"
    --     assert.are.equal(expected_str, output_str)
    -- end)

    it("returns fields correctly", function()
        local task = task_line.from_string("- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]")
        assert.is_true(task_line.is_valid(task))
        assert.are.equal("x", task.status)
        assert.are.equal("A", task.priority)
        assert.are.equal("this is a completed task", task.text)
        assert.are.equal("2024-02-02", task.due_date)
        assert.are.equal("Sagi", task.assignee)
        assert.are.equal("2024-02-01", task.followup_date)
        assert.are.equal("2", task.again_num)
        assert.are.equal("d", task.again_period)
        assert.are.equal("2024-02-02][2024-02-02-Tasks-Notes.md", task.note)

        task = task_line.from_string("- [x] this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]")
        assert.is_true(task_line.is_valid(task))
        assert.are.equal("x", task.status)
        assert.is_nil(task.priority)
        assert.are.equal("this is a completed task", task.text)
        assert.are.equal("2024-02-02", task.due_date)
        assert.are.equal("Sagi", task.assignee)
        assert.are.equal("2024-02-01", task.followup_date)
        assert.are.equal("2", task.again_num)
        assert.are.equal("d", task.again_period)
        assert.are.equal("2024-02-02][2024-02-02-Tasks-Notes.md", task.note)
    end)

     it("parses invalid lines", function()
         local input_str = "- [x] (A) this is a completed task | due:[2024-02-02] @[Sagi] ~:[2024-02-01] again:+2d note:[[2024-02-02][2024-02-02-Tasks-Notes.md]]"
         local task = task_line.from_string(input_str)
         assert.is_true(task_line.is_valid(task))
         task = task_line.from_string("- [ ] valid simple task")
         assert.is_true(task_line.is_valid(task))
         task = task_line.from_string("")
         assert.is_false(task_line.is_valid(task))
         task = task_line.from_string("just a line without a checkbox")
         assert.is_false(task_line.is_valid(task))
         task = task_line.from_string("[ ] invalid checkbox")
         assert.is_false(task_line.is_valid(task))
     end)
end)

