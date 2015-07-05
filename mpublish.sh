#!/bin/bash

#
# publishing meteor SPA into private nodejs server
# script:
#   convert meteor SPA application inro nodejs SPA application
#   transmit it to debian squeeze server
#   do details (create backup of last version, convert app, create dir, reconfigure nginx DNS proxy server, restart service's) to make app visible from WWW network
#
# server: debian squeeze with nginx and nodejs installed + starting coresponding script: /etc/init.d/nodejs
#
# softwork.pl - £ukasz Robak

function get_opts2() #getting pars convenient way
{
    #po³±czenie stringu parametrów:
    while [ "${1}" ];do
	PARLINE="$PARLINE ${1}"
	shift
    done
    if [ ! "$PARLINE" ]; then
	return 0
    fi
    
    #rozebranie parametrów na kawa³ki:
    PARLINE="${PARLINE} --"
    for i in $PARLINE;do
	if ( [ "${i#--}" != "${i}" ] && [ "$PAR" ] ) ;then
	    #pobranie parametru:
	    TMP=${PAR#--}
	    if [ ${#PAR} != ${#TMP} ];then
		if [ "$TMP" ];then
		    ISVALUE=$(echo $TMP | sed 's/^.*\(\=.*\)$/\1/g') #'
		    if [ "$ISVALUE" ];then
			NAME=$(echo $TMP | sed 's/^\(.*\)=\(.*\)$/\1/g') #'
			VALUE=$(echo $TMP | sed 's/^\(.*\)=\(.*\)$/\2/g') #'
		    else
			NAME="$TMP"
			VALUE=yes
		    fi
		    export $NAME="$VALUE"
		fi
	    fi
	
	    PAR="$i"
	else
	    if [ "$PAR" ];then
		PAR="${PAR} ${i}"
	    else
		PAR="${PAR}${i}"
	    fi
	fi
    done
}

function run(){
    echo -ne "run: "
    echo $*
    
    if ! $*
    then
	return 1
    fi
}

get_opts2 $*

# reading params
if [ -f "mpublish.conf" ];then
    . mpublish.conf
fi

if [ "$help" ] || [ ! "$server" ] || [ ! "$dir" ] || [ ! "$site" ]; then
    echo "mpublish.sh --server={<ssh_server>|<user>@<sshserver>} --dir=<node_containers_dir> --site=<full dns site name> [--genconfig] [--help]"
    if [ "$help" ];then
	echo "  (ex: mpublish.sh --server=11.11.11.11 --dir=/var/lib/node --site=some.test.pl --genconfig)"
	echo "  [--help] - you known what.."
	echo "  [--genconfig] - don't do.. but only generate mpublish.conf file (later you can use simply mpublish.sh without any params"
    fi
    exit 1
fi

# save config & exit
if [ "$genconfig" ]; then
    echo "export server=$server
export dir=$dir
export site=$site" > mpublish.conf
    exit 0
fi

# prerequisites
pwd="`pwd`"
origarch="`basename $pwd`.tar.gz"
projectname=$site
archname="$projectname.tar.gz"

# geting existing port number corelated with our service
nrcurrent=`ssh $server "cd $dir && ls -1 * | grep "${projectname}:" | cut -d: -f2"`

if [ ! "$nrcurrent" ];then
    # generate next available port number for running new server
    nrnew=`ssh $server "/etc/init.d/nodejs newnr"`
    nrcurrent=$nrnew
fi

if [ ! "$nrcurrent" ] && [ ! "$nrnew" ];then
    echo "error: can't count or generate unique service port number"
    exit 1
fi

# hardwork..
if ! run meteor build "$projectname" \
    || ! run ssh $server "mkdir -p $dir/$projectname:$nrcurrent $dir/$projectname.tmp $dir/$projectname.backup" \
    || ! run ssh $server "[ ! -f "$dir/$projectname.tmp/$archname" ] || rm -f $dir/$projectname/$archname >/dev/null 2>&1" \
    || ! run ssh $server "[ ! -d "$dir/$projectname:$nrcurrent" ] || tar zcf \`mktemp '$dir/$projectname.backup/${projectname}_tar.gz.XXXX'\` $dir/$projectname:$nrcurrent >/dev/null 2>&1" \
    || ! run scp "$projectname/$origarch" $server:$dir/$projectname.tmp/$archname \
    || ! run ssh $server "[ ! -d '$dir/$projectname.tmp/bundle' ] || rm -fr $dir/$projectname.tmp/bundle" \
    || ! run ssh $server "tar zxf $dir/$projectname.tmp/$archname -C $dir/$projectname.tmp >/dev/null 2>&1" \
    || ! run ssh $server "cd $dir/$projectname.tmp/bundle && npm install fibers semver underscore source-map-support >/dev/null" \
    || ! echo "run: ssh $server \"cd $dir/$projectname.tmp/bundle && cp -fra * $dir/$projectname:$nrcurrent\"" \
    || ! ssh $server "cd $dir/$projectname.tmp/bundle && cp -fra * $dir/$projectname:$nrcurrent 2>/tmp/log" \
    || ! run ssh $server "rm -fr $dir/$projectname.tmp >/dev/null 2>&1" \
    || ([ ! "$nrnew" ] || ! run ssh $server "/etc/init.d/nodejs new $projectname $nrcurrent") \
    || ! run ssh $server "/etc/init.d/nodejs checknodes" \
    || ! run rm -fr $projectname
then
    echo "stopping by error"
    exit 1
fi
