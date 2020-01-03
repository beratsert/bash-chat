#!/usr/bin/env bash

#CONFIGS
PORT=12345
USERNAME=''
MY_IP=''
IP_BLOCK=''
v_Announcer=''
v_Responser=''
v_Listener=''
v_Navigator=''
PacketType=''
PacketOwnerUsername=''
PacketOwnerIP=''

#Cleans old LOGs and creates Credentials
UserInfo() {
  rm Response_log.txt
  rm OnlineUsers_log.txt
  clear
  printf "Pls type your username\n"
  v_Announcer='0'
  v_Responser='0'
  v_Listener='0'
  read USERNAME
  MY_IP=$(hostname -I | sed 's/ //g')
  IP_BLOCK=$(echo "$MY_IP" | cut -d\. -f1-3)

  if ["$MY_IP" == ""]; then
  clear
  printf "$USERNAME,\n"
  printf "You don't have a connection.\n"
  printf "Please check your connection!\n"
  exit
  fi

  clear
  printf "Your username:$USERNAME \n\nYour Ip:$MY_IP\n\nIp block:$IP_BLOCK\n"
  ContinueCommand
}

ContinueCommand() {
  printf "\n\nTo continue please Enter.."
  read -r tmp
  clear
}

#Notifies all the users in the network
Announce() {
  clear
  printf "\nAnnouncer is running..Wait 3 sec\n"
  for i in {1..254}
    do
    echo "[$USERNAME, $MY_IP, announce]" | nc $IP_BLOCK.$i $PORT
  done
  v_Announcer='0'
}

#Listens the PORT and Sends packets to the PacketParser
ListenPort() {
  clear
  printf "\nNow, you are listening the Port:$PORT\n"

  while :
  do
    nc -lk $PORT | PacketParser
  done
}

#Parses Packets according to their types
PacketParser() {
  while read packet;do
    local name="$(echo "$packet" | sed 's/[][]//g' | cut -d ',' -f 1 | sed 's/ //g')"
    local ip="$(echo "$packet" | sed 's/[][]//g' | cut -d ',' -f 2 | sed 's/ //g')"
    local type="$(echo "$packet" | sed 's/[][]//g' | cut -d ',' -f 3 | sed 's/ //g')"

    if [ "$type" == "announce" ];then
      echo "$ip" >> Response_log.txt
    #  if(( $v_Responser == "1" ));then
        echo "[$USERNAME, $MY_IP, response]" | nc $ip $PORT
      #fi
      echo "$name,$ip" >> OnlineUsers_log.txt
      echo "Connection established with $name at $(date)" >> msg_$name.txt

    elif [ $type == "response" ];then
      echo "$name,$ip" >> OnlineUsers_log.txt
      echo "Connection established with $name at $(date)" >> msg_$name.txt

    elif [ $type == "message" ];then
      local message="$(echo "$packet" | sed 's/[][]//g' | cut -d ',' -f 4 | sed 's/ //g')"
      echo "$name at $(date):" >> msg_$name.txt
      echo "$message" >> msg_$name.txt
    fi

  done
}

GoBack() {
    printf "\n\nTo continue please Enter.."
    read -r tmp
    MainMenu
}

#In the main menu, by taking number from users, navigates to the tools
Navigator() {
  read -p "Please type the number of the selected command!" v_Navigator

  if [ $v_Navigator == "1" ];then

    if(( $v_Listener == "0" ));then
      v_Listener=1
      ListenPort &
      export ListenPort_PID=$!
      clear
    else
      v_Listener=0
      clear
      kill -9 $ListenPort_PID
      printf "\nListener is not running..\n"
    fi

    sleep 3

  elif [ $v_Navigator == "2" ];then

    if(( $v_Announcer == '0' ));then
      v_Announcer=1
      Announce &
      export Announce_PID=$!
      clear
    else
      v_Announcer=0
      clear
      kill -9 $Announce_PID
      printf "\nAnnouncer is not running..Wait 3 sec\n"
    fi

  sleep 3

  elif [ $v_Navigator == "3" ];then

    if(($v_Responser == '0' ));then
      v_Responser=1
      clear
      printf "\nResponser is running.. Wait 3 sec\n"
    else
      v_Responser=0
      clear
      printf "\nResponser is not running.. Wait 3 sec\n"
    fi

  sleep 3

  elif [ $v_Navigator == "0" ];then
    kill -9 $Announce_PID
    kill -9 $ListenPort_PID
    kill -9 $Response_PID
    clear
    printf "\n\nSee you!\n\n"
    kill -9 $$

  elif [ $v_Navigator == "4" ];then
    clear
    cat OnlineUsers_log.txt
    GoBack

  elif [ $v_Navigator == "5" ];then
    Messages
  fi

  MainMenu
}

#When you desire to see Mesages, it lists the users that you have an interraction with.
#By typing the name of the user, you can access Chat.
Messages() {
  clear
  printf "Messages from... \n"
  ls | grep "msg_" | cut -d '.' -f 1 | cut --complement -c 1-4
  printf "\nPls type the person you desire to chat or type 0 to Main Menu.. \n \n"
  read -r desired_user
  if [ $desired_user == "0" ];then
    MainMenu
  else
    clear
    cat msg_$desired_user.txt
    printf "\nType your message,then Enter.."
    printf "\nTo return Messages, please type '0' "
    while :
     do
       read -r my_own_message

       if [ $my_own_message == "0" ];then
         Messages
       else
         local Destination="$(cat OnlineUsers_log.txt | grep "$desired_user" | cut -d ',' -f 2 | sed 's/ //g')"
         printf "$Destination"
         sleep 3
         echo "[$USERNAME, $MY_IP, message, $my_own_message]" | nc $Destination $PORT
         echo "$USERNAME at $(date):" >> msg_$desired_user.txt
         echo "$my_own_message" >> msg_$desired_user.txt
         printf "\n$USERNAME at $(date):\n$my_own_message\n"
         printf "\nType your message,then Enter.."
         printf "\nTo return Messages, please type '0' "
         sleep 3
         clear
         cat msg_$desired_user.txt
      fi

    done
  fi
}

#MainMenu
MainMenu() {
  clear
  printf "You are in the main menu!\n"
  printf "\n************\n"
  printf "\nAs default, the program does not listen the PORT and respond the packets."
  printf "\nThe first command to listen the PORT!"
  printf "\nThe second command to send 'announce' packets!"
  printf "\nThe third command to send 'response' packets!"
  printf "\nAfter activating listener and responser or announcer, use forth command to list of Online Users!"
  printf "\nFifth command leads you to the Messages, you can see both old log and new messages!\n"
  printf "\nStatus:\n"
  printf "Listener--->$v_Listener\n"
  printf "Announcer--->$v_Announcer\n"
  printf "Responser--->$v_Responser\n"
  printf "\nCommands\n"
  printf "1)Listen the PORT\n"
  printf "2)Broadcast the Announcements\n"
  printf "3)Respond other users\n"
  printf "4)List the Online Users\n"
  printf "5)Go to Messages\n"
  printf "\n0)Exit\n\n"
  Navigator
}


clear
printf "Welcome to Bash-Chat\n$(date)\n"
ContinueCommand
UserInfo
MainMenu
