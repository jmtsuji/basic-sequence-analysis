# basic-sequence-analysis
BETA personal scripts to perform basic FastX file manipulations

Copyright Jackson M. Tsuji, 2017

# text_find_and_replace.sh
Test code: 
```
file_location="test_data/text_find_and_replace"
text_find_and_replace.sh ${file_location}/test_replacements.tsv ${file_location}/test_input.txt ${file_location}/output.txt
cmp ${file_location}/output.txt ${file_location}/successful_output.txt
if [ $(echo $?) == 0 ]; then
echo "Test passed."; else
echo "Test FAILED."
fi
```
