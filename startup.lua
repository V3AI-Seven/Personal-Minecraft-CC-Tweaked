-- ComputerCraft Tweaked script to run all files in a directory
-- Usage: runAllFiles(directory_path)

function runAllFiles(directory)
    -- Check if directory exists
    if not fs.exists(directory) then
        print("Error: Directory '" .. directory .. "' does not exist")
        return false
    end
    
    -- Check if path is actually a directory
    if not fs.isDir(directory) then
        print("Error: '" .. directory .. "' is not a directory")
        return false
    end
    
    print("Running all files in directory: " .. directory)
    print("----------------------------------------")
    
    -- Get list of files in directory
    local files = fs.list(directory)
    local executedCount = 0
    local errorCount = 0
    
    -- Sort files alphabetically for consistent execution order
    table.sort(files)
    
    for _, filename in ipairs(files) do
        local filepath = fs.combine(directory, filename)
        
        -- Skip directories and only process .lua files
        if not fs.isDir(filepath) and filename:match("%.lua$") then
            print("Executing: " .. filename)
            
            -- Attempt to run the file
            local success, error = pcall(function()
                dofile(filepath)
            end)
            
            if success then
                print("  ✓ " .. filename .. " executed successfully")
                executedCount = executedCount + 1
            else
                print("  ✗ Error in " .. filename .. ": " .. tostring(error))
                errorCount = errorCount + 1
            end
            
            -- Add a small delay between executions
            sleep(0.1)
        end
    end
    
    print("----------------------------------------")
    print("Execution complete:")
    print("  Files executed: " .. executedCount)
    print("  Errors: " .. errorCount)
    
    return errorCount == 0
end

-- Function to run files in a directory with error handling and user confirmation
function runDirectory(directory)
    if not directory then
        print("Usage: runDirectory(directory_path)")
        return
    end
    
    print("About to run all .lua files in: " .. directory)
    print("Press 'y' to continue, any other key to cancel...")
    
    local event, key = os.pullEvent("key")
    if key == keys.y then
        return runAllFiles(directory)
    else
        print("Operation cancelled")
        return false
    end
end

-- Function to recursively run files in directory and subdirectories
function runAllFilesRecursive(directory)
    -- Check if directory exists
    if not fs.exists(directory) then
        print("Error: Directory '" .. directory .. "' does not exist")
        return false
    end
    
    if not fs.isDir(directory) then
        print("Error: '" .. directory .. "' is not a directory")
        return false
    end
    
    print("Recursively running files in: " .. directory)
    local totalExecuted = 0
    local totalErrors = 0
    
    local function processDirectory(dir, depth)
        local indent = string.rep("  ", depth)
        print(indent .. "Processing: " .. dir)
        
        local files = fs.list(dir)
        table.sort(files)
        
        for _, filename in ipairs(files) do
            local filepath = fs.combine(dir, filename)
            
            if fs.isDir(filepath) then
                -- Recursively process subdirectories
                local subExecuted, subErrors = processDirectory(filepath, depth + 1)
                totalExecuted = totalExecuted + subExecuted
                totalErrors = totalErrors + subErrors
            elseif filename:match("%.lua$") then
                -- Execute lua files
                print(indent .. "  Executing: " .. filename)
                
                local success, error = pcall(function()
                    dofile(filepath)
                end)
                
                if success then
                    print(indent .. "    ✓ Success")
                    totalExecuted = totalExecuted + 1
                else
                    print(indent .. "    ✗ Error: " .. tostring(error))
                    totalErrors = totalErrors + 1
                end
                
                sleep(0.1)
            end
        end
        
        return totalExecuted, totalErrors
    end
    
    processDirectory(directory, 0)
    
    print("----------------------------------------")
    print("Recursive execution complete:")
    print("  Total files executed: " .. totalExecuted)
    print("  Total errors: " .. totalErrors)
    
    return totalErrors == 0
end

runAllFilesRecursive("ballisticsCalc")