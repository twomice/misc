This is a command-line dialer for Google Voice. 

gv.php is the script to call. I recommend symlinking it from 
somewhere in your path.

CONFIGURATION:
gv expects a config script at ~/.gv.conf
See gv.conf.example for an example.

USAGE:
gv cmd args
where cmd is one of the following commands, with required args:
    call (number)
        Place a call to (number) from configured HOMENUMBER

    sms (number) (text)
        Send an sms message (text) to (number)

    toggle (arg)
        Set one of your phones as the active forward. (arg) can be one of the following:
            N
                Enable the phone with the id number N
            list
                List phones with their id numbers

