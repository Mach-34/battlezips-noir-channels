# #!/bin/bash

# # Define file path
# FILE="./node_modules/@noir-lang/noir-source-resolver/lib/index.js"

# # Remove the "export " pattern from the file
# sed -i 's/export //g' "$FILE"

# # Append the desired text to the end of the file
# echo -e "\nmodule.exports = {\n    read_file,\n    initialiseResolver\n}" >> "$FILE"