#ifndef CONFIG_H
#define CONFIG_H

//when PING_DATA sent will set user's ping to this value (reset) and wait for next ping value
#define DEFAULT_CLIENT_PING -1

/*
 if user ping is equal to DEFAULT PING (not respond for a while)
 and user->connectionLostCounter exceed CLIENT_MAX.. will disconnect user.
*/
#define CLIENT_MAX_CONNECTIONLOST_COUNT 500


//if user connectionLostCounter==0 , start timer and on each trigger (3s) will increase user->connectionLostCounter
#define CLIENT_CONNECTIONLOST_TIMER_INTERVAL 3000 //3s


/*
   every 6s send CommandHandler::PING_DATA to users and
   expect receive CommandHandler::PONG_DATA
   otherwise make user->connetionLostTimer start
   on each trigger of that timer would increase user's connection lost counter.
*/
#define SERVER_PING_USERS_TIMER_INTERVAL 6000 //6s

#define SERVER_NETWORK_HOST_PORT 5023
#endif // CONFIG_H
