#!/bin/bash

#1: THIS BASH SCRIPT FIRST ASKS THE USER FOR A VALID USER NAME/ID INORDER TO CHECK WHETHER THE USER NAME/ID PROVIDED IS PRESENT ON THE SYSTEM OR NOT
#2: IF THE USER NAME/ID IS PRESENT, THE SCRIPT THEN ASKS THE USER FOR A VALID GROUP NAME/ID AND AGAIN CHECK WHETHER THE GROUP NAME/ID PROVIDED IS PRESENT ON THE SYSTEM OR NOT
#3: IF THE GROUP NAME/ID IS PRESENT ON THE SYSTEM THEN THE SCRIPT WILL FURTHER CHECK WHETHER THE USERNAME PROVIDED IS A MEMBER OF THE GROUP OR NOT
#4: IF THE USERNAME IS THE MEMBER OF THE GROUP THEN THE SCRIPT WILL ASK THE USER FOR A VALID DIRECTORY AND CHECK IF THE DIRECTORY EXISTS ON THE SYSTEM OR NOT

#         ---NOTE THAT IF ANY OF THE INPUT PROVIDED BY THE USER IS INCORRECT, THE SCRIPT WILL KEEP ON ASKING FOR A VALID INPUT UNTIL IT WILL FIND ONE---

#5: NOW THAT ALL THE THREE INPUTS ARE VALID THE SCRIPT WILL GENERATE A LIST OF FILES FROM THAT DIRECTORY RECURSIVELY
#6: NOW FOR EVERY FILE GENERATED, THE SCRIPT WILL FIRST CHECK WHETHER THE USERNAME PROVIDED BY THE USER MATCHES THE OWNER OF THE FILE OR NOT
#7: IF THERE IS A MATCH, THEN THE SCRIPT WILL FURTHER CHECK WHETHER THE OWNER OF THE FILE HAS EXECUTION PERMISSION OR NOT DENOTED BY "x"
#8: IF THERE IS NOT A MATCH, THE SCRIPT WILL SKIP THIS STEP AND CHECK WHETHER THE GROUPNAME PROVIDED BY THE USER MATCHES THE GROUPNAME OF THE FILE OR NOT
#9: IF THERE IS A MATCH, THEN THE SCRIPT WILL FURTHER CHECK WHETHER THE GROUP OF THE FILE HAS EXECUTION PERMISSION OR NOT DENOTED BY "x"
#10: IF THERE IS NOT A MATCH, THE SCRIPT WILL SKIP THIS STEP AND CHECK WHETHER THE "other" OF THE FILE HAS EXECUTION PERMISSION OR NOT DENOTED BY "x"
#11: NOW THAT THE FILES ARE GENERATED WITH THE PROPER EXECUTION PERMISSION, THE LAST STEP WILL BE TO CLEAN UP THE TEMPORARY DATA CREATED DURING THE PROCESS




#THIS "user()" FUNCTION WILL ASK AN INPUT (USERID OR USERNAME) FROM THE USER AND CHECK WHETHER IT IS PRESENT IN THE "/etc/passwd" DIRECTORY OR NOT



user(){

read -p "please enter a valid username or userid: " usernameid
re='^[0-9]+$'
CHECKNAME=$( getent passwd "$usernameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE INPUT FOR USERID IS A NUMBER OR NOT BY COMPARING IT TO THE "re" VARIABLE
#IF IT IS A NUMBER THEN IT WILL LOOK FOR ITS MATCHING USERNAME IN THE "/etc/passwd" DIRECTORY 

if [[ "$usernameid" =~ $re ]] && [[ "$usernameid" > 0 ]]; then
       	USERNAME=$( getent passwd "$usernameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE "USERNAME" VARIABLE IS EMPTY(MEANING NO MATCH WAS FOUND) OR NOT(MEANS A MATCH WAS FOUND!!) 
       	if [[ -z "$USERNAME" ]]; then
               	echo "the userid is not valid"
		user
       	else
               	echo "userid is valid "
#WHEN THE USERID IS VALID IT WILL CALL THE "groupcall" FUNCTION AND ALONG WITH THAT IT WILL PASS THE VALID USERNAME AS AN ARGUMENT
		groupcall "$CHECKNAME"
       	fi
else

#IF IT IS A NAME THEN IT WILL LOOK FOR ITS MATCHING USERID IN THE SYSTEM
       	USERID=$( id -u "$usernameid" )
	if [[ -z "$USERID" ]]; then
               	echo "the username is not valid"
		user
       	else
               	echo "the username is valid"
		groupcall "$CHECKNAME"
       	fi
fi
}




#THIS "groupcall()" FUNCTION WILL ASK AN INPUT (GROUPID OR GROUPNAME) FROM THE USER AND CHECK WHETHER IT IS PRESENT IN THE "/etc/passwd" DIRECTORY OR NOT

groupcall(){

USR="$1"

read -p "please enter a valid groupname or groupid: " groupnameid

re='^[0-9]+$'


CHECKNAMEGRP=$( getent group "$groupnameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE INPUT FOR GROUPID IS A NUMBER OR NOT BY COMPARING IT TO THE "re" VARIABLE
#IF IT IS A NUMBER THEN IT WILL LOOK FOR ITS MATCHING GROUPNAME IN THE "/etc/passwd" DIRECTORY

if [[ "$groupnameid" =~ $re ]] && [[ "$groupnameid" > 0 ]]; then
        GROUPNAME=$( getent group "$groupnameid" | cut -d : -f 1 )
#	GIDCATCH=$( getent group "$groupnameid" | cut -d : -f 3 )
        if [[ -z "$GROUPNAME" ]]; then
                echo "the groupid is not valid"
                groupcall "$1"
        else
                echo "groupid is valid"

#THIS CONDITION WILL CHECK FOR THE POSSIBLE NUMBER OF GROUPS THE USERNAME BELONGS TO 
#SO IF HE USERNAME DOES BELONG TO A GROUP THE "CHECK" VARIABLE WILL CATCH THE NUMBER OF GROUPS THE USER IS A MEMBER OF
#AND IT WILL CALL THE "direct" FUNCTION AND ALONG WITH THAT IT WILL PASS THE VALID USERNAME AND GROUPNAME AS THE ARGUMENTS 
		IDMATCH=$( getent passwd "$GIDCATCH" | cut -d : -f 4 )
		CHECK=$(id -Gn "$USR" | grep -c "$CHECKNAMEGRP")
#                if [[ "$CHECK" > 0 ]] && [[ "$GIDCATCH" == "$IDMATCH" ]]; then
		if [[ "$CHECK" > 0 ]]; then
                        echo "and $USR is a member of group $CHECKNAMEGRP"
                        direct "$USR" "$CHECKNAMEGRP"
                else
                        echo "but $USR is not a member of group $CHECKNAMEGRP"
			groupcall "$1"
                fi

        fi
else
#IF IT IS A NAME THEN IT WILL LOOK FOR ITS MATCHING GROUPID IN THE SYSTEM

	GROUPID=$( getent group "$groupnameid" | cut -d : -f 1 )
        if [[ -z "$GROUPID" ]]; then
                echo "the groupname is not valid"
                groupcall "$1"
        else
                echo "the groupname is valid"
        	CHECK=$(id -Gn "$CHECKNAME" | grep -c "$CHECKNAMEGRP")
		if [[ "$CHECK" > 0 ]]; then
                        echo "and $USR is a member of group $CHECKNAMEGRP"
			direct "$USR" "$CHECKNAMEGRP"
                else
                        echo "but $USR is not a member of group $CHECKNAMEGRP"
			groupcall "$1"
                fi
	fi
fi

}




#THIS FUNCTION WILL CHECK WHETHER THE DIRECTORY GIVEN BY THE USER IS VALID OR NOT
#IF IT IS VALID THEN IT WILL CALL THE "generate" FUNCTION AND ALONG WITH THAT IT WILL PASS THE VALID USERNAME AND GROUPNAME AS THE ARGUMENTS

direct(){
read -p "please enter a valid directoryname: " directname

US1="$1"

GS1="$2"

if [ -d "$directname" ]; then

        echo "directory is present"
	generate "$US1" "$GS1" "$directname"

else
        echo "no such directory"
	direct "$1" "$2"
fi


}



#THIS FUNCTION WILL GENERATE THE LIST OF FILES FROM THE DIRECTORY AND STORE IT IN AN ARRAY AND LATER WILL LIST OUT THE FILE PERMISSIONS

generate(){

#echo "generating files....."
dname="$3"
#echo "$dname"

i=0
while read line
do
        filenames[$i]="$line"
        (( i++ ))

done< <(ls -R -al "$dname")

echo "total number of files found in the directory are ${#filenames[@]}"

echo "please wait a moment while the files are being generated.................."

for (( i=0; i<=${#filenames[@]}; i++ ))
do
	STARTC=$( echo "${filenames[i]}" | awk '{print $1}' | cut -b 1 )

	if [[ "$STARTC" == "-" ]] || [[ "$STARTC" == "d" ]]; then
        	RESTCOM=$( echo "${filenames[i]}" | awk '{print $3,$4,$5,$6,$7,$8,$9}' )
        	NAMECHECK=$( echo "${filenames[i]}" | awk '{print $3}' )
        	INSIDEFILE=$( echo "${filenames[i]}" | awk '{print $9}' )
        	GROUPCHECK=$( echo "${filenames[i]}" | awk '{print $4}' )
       		ALLPERM=$( echo "${filenames[i]}" | awk '{print $1}' )
        	PERMUSER=$( echo "${filenames[i]}" | awk '{print $1}' | cut -b 4 )
        	PERMGROUP=$( echo "${filenames[i]}" | awk '{print $1}' | cut -b 7 )
        	PERMOTHER=$( echo "${filenames[i]}" | awk '{print $1}' | cut -b 10 )
        	OUTPUT=$( echo " $3/$INSIDEFILE:$ALLPERM $RESTCOM" )

		touch name.txt
		touch group.txt
		touch other.txt

#THIS CONDITION WILL CHECK WHETHER THE USERNAME MATCHES THE FILE OWNER

        	if [[ "$1" == "$NAMECHECK" ]]; then

                	if [[ "$PERMUSER" == "x" ]]; then

                        	UVAL=U
                        	UVALEX=Y
#				echo "$OUTPUT:$UVAL$UVALEX"
                        	echo "$OUTPUT:$UVAL$UVALEX" >> name.txt
			else

                        	UVAL=U
                        	UVALEX=N
#				echo "$OUTPUT:$UVAL$UVALEX"
                        	echo "$OUTPUT:$UVAL$UVALEX" >> name.txt
                	fi

#IF THE USERNAME DOES NOT MATCHES THEN THIS BELOW CONDITION WILL CHECK WHETHER THE GROUPNAME WILL MATCH THE FILE GROUPNAME

        	elif [[ "$2" == "$GROUPCHECK" ]]; then

                	if [[ "$PERMGROUP" == "x" ]]; then

                        	GVAL=G
                        	GVALEX=Y
#				echo "$OUTPUT:$GVAL$GVALEX"
                        	echo "$OUTPUT:$GVAL$GVALEX" >> group.txt
                	else

                        	GVAL=G
                        	GVALEX=N
#				echo "$OUTPUT:$UVAL$GVALEX"
                        	echo "$OUTPUT:$UVAL$GVALEX" >> group.txt
                	fi

#IF NEITHER THE USERNAME NOR THE GROUPNAME MATCHES THEN THIS CONDTION WILL CHECK WHETHER OTHER HAS EXECUTION PERMISSION OR NOT
        	elif [[ "$PERMOTHER" == "x" ]]; then
                	OTVALUE=O
                	OTHEREX=Y
#			echo "$OUTPUT:$OTVALUE$OTHEREX"
			echo "$OUTPUT:$OTVALUE$OTHEREX" >> other.txt
        	else
                	OTVALUE=O
                	OTHEREX=N
#			echo "$OUTPUT:$OTVALUE$OTHEREX"
                	echo "$OUTPUT:$OTVALUE$OTHEREX" >> other.txt
        	fi
	else
		continue

	fi
filechk
done

}



#this function will check if the final directory where the output will be generated exists or not
#if it doesnt then it will create one along with concatenating the final list with permissions

filechk(){

touch executable_files.txt
less name.txt >> executable_files.txt
less group.txt >> executable_files.txt
less other.txt >> executable_files.txt


	if [[ -d ~/project/ ]]; then
		rm ~/project/executable_files.txt
		cp executable_files.txt ~/project/executable_files.txt
		
	else
		mkdir ~/project
		cp executable_files.txt ~/project/executable_files.txt
		
	fi
trap finish EXIT

}

#THIS TRAP FUNCTION WILL REMOVE THE TEMPORARY FILES CREATED DURING THE PROCESS

finish(){

rm name.txt
rm group.txt
rm other.txt
rm executable_files.txt
echo " "
echo "EXECUTION DONE !!! PLEASE CHECK the text file named executable_files in the project directory of your home"

}



#below functions are used for checking the valid inputs passed as arguments on the command line

#this function will check if the first argument is present or not if it is not present input will be taken during runtime
#if the first argument is present the condition will check further for the other two arguments
#if all the 3 arguments are present it will pass those arguments while calling userarg function

going(){
	if [[ -z "$1" ]]; then
		echo "taking arguments in runtime....."
		user
	elif [[ -z "$2" ]] || [[ -z "$3" ]]; then
		echo "other arguments are missing, please enter all three arguments again "
	else
		echo "arguments have been taken from the command line......"
		userarg "$1" "$2" "$3"

	fi
}


#this function will check for a valid username or userid
#if the id is valid it will pass the arguments to groupcallarg function for checking the groupid

userarg(){

usernameid="$1"
GRN="$2"
DIN="$3"

re='^[0-9]+$'
CHECKNAME=$( getent passwd "$usernameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE INPUT FOR USERID IS A NUMBER OR NOT BY COMPARING IT TO THE "re" VARIABLE
#IF IT IS A NUMBER THEN IT WILL LOOK FOR ITS MATCHING USERNAME IN THE "/etc/passwd" DIRECTORY

if [[ "$usernameid" =~ $re ]] && [[ "$usernameid" > 0 ]]; then
        USERNAME=$( getent passwd "$usernameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE "USERNAME" VARIABLE IS EMPTY(MEANING NO MATCH WAS FOUND) OR NOT(MEANS A MATCH WAS FOUND!!)
        if [[ -z "$USERNAME" ]]; then
                echo "the userid is not valid, please run the entire script again and enter the valid arguments"

        else
                echo "userid is valid "
#WHEN THE USERID IS VALID IT WILL CALL THE "groupcall" FUNCTION AND ALONG WITH THAT IT WILL PASS THE VALID USERNAME AS AN ARGUMENT
                groupcallarg "$CHECKNAME" "$GRN" "$DIN"
        fi
else

#IF IT IS A NAME THEN IT WILL LOOK FOR ITS MATCHING USERID IN THE SYSTEM
        USERID=$( id -u "$usernameid" )
        if [[ -z "$USERID" ]]; then
                echo "the username is not valid, please run the entire script again and enter the valid arguments"

        else
                echo "the username is valid"
                groupcallarg "$CHECKNAME" "$GRN" "$DIN"
        fi
fi
}

#this function will check for a valid groupname or groupid
#it will further check if the user is primary or not and whether the user is a member of the input group or not
#if the id is valid it will pass the arguments to directarg function for checking the directory


groupcallarg(){

USR="$1"

groupnameid="$2"

DRD="$3"


re='^[0-9]+$'


CHECKNAMEGRP=$( getent group "$groupnameid" | cut -d : -f 1 )

#THIS CONDITION WILL CHECK WHETHER THE INPUT FOR GROUPID IS A NUMBER OR NOT BY COMPARING IT TO THE "re" VARIABLE
#IF IT IS A NUMBER THEN IT WILL LOOK FOR ITS MATCHING GROUPNAME IN THE "/etc/passwd" DIRECTORY

if [[ "$groupnameid" =~ $re ]] && [[ "$groupnameid" > 0 ]]; then
        GROUPNAME=$( getent group "$groupnameid" | cut -d : -f 1 )

        if [[ -z "$GROUPNAME" ]]; then
                echo "the groupid is not valid, please run the entire script again and pass the valid arguments"

        else
                echo "groupid is valid"

#THIS CONDITION WILL CHECK FOR THE POSSIBLE NUMBER OF GROUPS THE USERNAME BELONGS TO
#SO IF HE USERNAME DOES BELONG TO A GROUP THE "CHECK" VARIABLE WILL CATCH THE NUMBER OF GROUPS THE USER IS A MEMBER OF
#AND IT WILL CALL THE "direct" FUNCTION AND ALONG WITH THAT IT WILL PASS THE VALID USERNAME AND GROUPNAME AS THE ARGUMENTS

                CHECK=$(id -Gn "$USR" | grep -c "$CHECKNAMEGRP")

                if [[ "$CHECK" > 0 ]]; then
                        echo "and $USR is a member of group $CHECKNAMEGRP"
                        directarg "$USR" "$CHECKNAMEGRP" "$DRD"
                else
                        echo "but $USR is not a member of group $CHECKNAMEGRP, please run the entire script again and pass the valid arguments"

                fi

        fi
else
#IF IT IS A NAME THEN IT WILL LOOK FOR ITS MATCHING GROUPID IN THE SYSTEM

        GROUPID=$( getent group "$groupnameid" | cut -d : -f 1 )
        if [[ -z "$GROUPID" ]]; then
                echo "the groupname is not valid,  please run the entire script again and pass the valid arguments"

        else
                echo "the groupname is valid"
                CHECK=$(id -Gn "$CHECKNAME" | grep -c "$CHECKNAMEGRP")
                if [[ "$CHECK" > 0 ]]; then
                        echo "and $USR is a member of group $CHECKNAMEGRP"
                        directarg "$USR" "$CHECKNAMEGRP" "$DRD"
                else
                        echo "but $USR is not a member of group $CHECKNAMEGRP,  please run the entire script again and pass the valid arguments"

                fi
        fi
fi

}


#this function checks whether the input directory given by the user is a valid one or not
#if it is valid then it will pass all the 3 arguments to the generate function to generate the list of files

directarg(){

US1="$1"

GS1="$2"

directname="$3"

if [ -d "$directname" ]; then

        echo "directory is present"
        generate "$US1" "$GS1" "$directname"

else
        echo "no such directory,  please run the entire script again and pass the valid arguments"

fi


}

#---this below function will check whether user is passing the argument during runtime or on the command line

going "$1" "$2" "$3"
