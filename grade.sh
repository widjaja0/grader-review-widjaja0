# ---------------------- SETUP ----------------------

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS_NT*)   machine=Git;;
    *)          machine="UNKNOWN:${unameOut}"
esac

# VARIABLES
# the relative path of JUNIT files
if [[ ${machine} == "MinGw" ]]
then
	CPATH='.;lib/hamcrest-core-1.3.jar;lib/junit-4.13.2.jar'
else
	CPATH='.:lib/hamcrest-core-1.3.jar:lib/junit-4.13.2.jar'
fi
# borders
BORDER='----------------------'

# remove folders to make fresh grading files/folders
rm -rf student-submission
rm -rf grading-area

# make a new grading-area
mkdir grading-area

# clone the student's repository into student-submission
git clone $1 student-submission 2> gitclone-output.txt

# checks if the url was invalid
if [[ $? -ne 0 ]]
then
	echo "$BORDER"
	echo "Invalid URL."
	echo "Score: 0"
	echo "$BORDER"
	exit 1
fi

echo "$BORDER"
echo 'Finished cloning the Github Repository.'
echo "$BORDER"

# copy all the root java files into the grading-area
# recursively copy all the JUNIT files into the grading-area
# attempts to copy the student's submission for ListExamples.java into the grading-area

cp *.java grading-area
cp -r lib grading-area
cp student-submission/ListExamples.java grading-area 2> potential-copy-error.txt

# change working directory into the grading-area
cd grading-area

# ---------------------- GRADING ----------------------

# the ListExamples.java file does not exist in the grading area, the student did not name their file correctly
# give them a 0
if ! [ -f ListExamples.java ]
then
	echo "Missing ListExamples.java in student submission! Check that you have submitted ListExamples.java with the proper file path or file naming convention."
	echo "Score: 0"
	echo "$BORDER"
	exit 1
fi

# attempt to compile all the java files and parse the JUNIT library to enable tester files to work
javac -cp $CPATH *.java

# the previous compile command returned an error
# give them a 0
if [[ $? -ne 0 ]]
then
	echo "$BORDER"
	echo "One of your files has a COMPILE TIME ERROR! Refer to the error message above for more details."
	echo "Score: 0"
	echo "$BORDER"
	exit 1
fi

# attempt to run testers against their code
java -cp $CPATH org.junit.runner.JUnitCore TestListExamples > test-output.txt

# if any of their tests failed
if [[ $? -ne 0 ]]
then
	# --------- PARTIAL OR NO PASS ---------
	# grab the error output of the tester from test-output.txt
	ERRORS=$(cat test-output.txt | head -n 6)
	echo "JUNIT OUTPUT:"
	echo ""
	echo -e "$ERRORS"
	echo "$BORDER"

	# grab the tests run / failures output of the tester from test-output.txt
	# TESTSRUN = number of tests run
	# FAILURES = number of failures
	TESTOUT=$(cat test-output.txt | tail -n 2 | head -n 1)
	TESTSRUN=$(echo $TESTOUT | awk -F[', '] '{print $3}')
	NUMFAILED=$(echo $TESTOUT | awk -F[', '] '{print $6}')

	# get their score from NUMPASSED divided by the number of TESTSRUN
	NUMPASSED=$(( TESTSRUN - NUMFAILED ))
	SCORE=$(( (NUMPASSED * 100) / TESTSRUN ))

	# print their score
	echo 'You passed' $NUMPASSED 'out of' $TESTSRUN 'tests.'
	echo 'Your score is:' $SCORE '/ 100'
	echo "$BORDER"
else
	# --------- FULL PASS ---------
	# get their score from the number of tests run
	TESTOUT=$(cat test-output.txt | tail -n 2 | head -n 1)
	TESTSPASSED=$(echo $TESTOUT | awk -F'[()]' '{print $2}' | cut -d' ' -f1)

	# print their score
	echo 'You passed' $TESTSPASSED 'out of' $TESTSPASSED 'tests.'
	echo 'Your score is: 100 / 100'
	echo "$BORDER"
fi





