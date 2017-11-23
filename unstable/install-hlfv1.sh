ME=`basename "$0"`
if [ "${ME}" = "install-hlfv1.sh" ]; then
  echo "Please re-run as >   cat install-hlfv1.sh | bash"
  exit 1
fi
(cat > composer.sh; chmod +x composer.sh; exec bash composer.sh)
#!/bin/bash
set -e

# Docker stop function
function stop()
{
P1=$(docker ps -q)
if [ "${P1}" != "" ]; then
  echo "Killing all running containers"  &2> /dev/null
  docker kill ${P1}
fi

P2=$(docker ps -aq)
if [ "${P2}" != "" ]; then
  echo "Removing all containers"  &2> /dev/null
  docker rm ${P2} -f
fi
}

if [ "$1" == "stop" ]; then
 echo "Stopping all Docker containers" >&2
 stop
 exit 0
fi

# Get the current directory.
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the full path to this script.
SOURCE="${DIR}/composer.sh"

# Create a work directory for extracting files into.
WORKDIR="$(pwd)/composer-data"
rm -rf "${WORKDIR}" && mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

# Find the PAYLOAD: marker in this script.
PAYLOAD_LINE=$(grep -a -n '^PAYLOAD:$' "${SOURCE}" | cut -d ':' -f 1)
echo PAYLOAD_LINE=${PAYLOAD_LINE}

# Find and extract the payload in this script.
PAYLOAD_START=$((PAYLOAD_LINE + 1))
echo PAYLOAD_START=${PAYLOAD_START}
tail -n +${PAYLOAD_START} "${SOURCE}" | tar -xzf -

# stop all the docker containers
stop



# run the fabric-dev-scripts to get a running fabric
./fabric-dev-servers/downloadFabric.sh
./fabric-dev-servers/startFabric.sh

# pull and tage the correct image for the installer
docker pull hyperledger/composer-playground:0.15.3
docker tag hyperledger/composer-playground:0.15.3 hyperledger/composer-playground:latest

# Start all composer
docker-compose -p composer -f docker-compose-playground.yml up -d

# manually create the card store
docker exec composer mkdir /home/composer/.composer

# build the card store locally first
rm -fr /tmp/onelinecard
mkdir /tmp/onelinecard
mkdir /tmp/onelinecard/cards
mkdir /tmp/onelinecard/client-data
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/client-data/PeerAdmin@hlfv1
mkdir /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials

# copy the various material into the local card store
cd fabric-dev-servers/fabric-scripts/hlfv1/composer
cp creds/* /tmp/onelinecard/client-data/PeerAdmin@hlfv1
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/signcerts/Admin@org1.example.com-cert.pem /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/certificate
cp crypto-config/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp/keystore/114aab0e76bf0c78308f89efc4b8c9423e31568da0c340ca187a9b17aa9a4457_sk /tmp/onelinecard/cards/PeerAdmin@hlfv1/credentials/privateKey
echo '{"version":1,"userName":"PeerAdmin","roles":["PeerAdmin", "ChannelAdmin"]}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/metadata.json
echo '{
    "type": "hlfv1",
    "name": "hlfv1",
    "orderers": [
       { "url" : "grpc://orderer.example.com:7050" }
    ],
    "ca": { "url": "http://ca.org1.example.com:7054",
            "name": "ca.org1.example.com"
    },
    "peers": [
        {
            "requestURL": "grpc://peer0.org1.example.com:7051",
            "eventURL": "grpc://peer0.org1.example.com:7053"
        }
    ],
    "channel": "composerchannel",
    "mspID": "Org1MSP",
    "timeout": 300
}' > /tmp/onelinecard/cards/PeerAdmin@hlfv1/connection.json

# transfer the local card store into the container
cd /tmp/onelinecard
tar -cv * | docker exec -i composer tar x -C /home/composer/.composer
rm -fr /tmp/onelinecard

cd "${WORKDIR}"

# Wait for playground to start
sleep 5

# Kill and remove any running Docker containers.
##docker-compose -p composer kill
##docker-compose -p composer down --remove-orphans

# Kill any other Docker containers.
##docker ps -aq | xargs docker rm -f

# Open the playground in a web browser.
case "$(uname)" in
"Darwin") open http://localhost:8080
          ;;
"Linux")  if [ -n "$BROWSER" ] ; then
	       	        $BROWSER http://localhost:8080
	        elif    which xdg-open > /dev/null ; then
	                xdg-open http://localhost:8080
          elif  	which gnome-open > /dev/null ; then
	                gnome-open http://localhost:8080
          #elif other types blah blah
	        else
    	            echo "Could not detect web browser to use - please launch Composer Playground URL using your chosen browser ie: <browser executable name> http://localhost:8080 or set your BROWSER variable to the browser launcher in your PATH"
	        fi
          ;;
*)        echo "Playground not launched - this OS is currently not supported "
          ;;
esac

echo
echo "--------------------------------------------------------------------------------------"
echo "Hyperledger Fabric and Hyperledger Composer installed, and Composer Playground launched"
echo "Please use 'composer.sh' to re-start, and 'composer.sh stop' to shutdown all the Fabric and Composer docker images"

# Exit; this is required as the payload immediately follows.
exit 0
PAYLOAD:
� �Z �=�r��r�=��)'�T��d�fa��^�$ �(��o-�o�%��C"и����'���@~#���|G~ ���WQ�dJ��fWI$gz�{.=�=�����V@1[m�Ɓ�.���j����p �h�|�c7�I!�G�a���?x|T�E!������B�K�h��x��P�`��Lc�	kcc��)��d��1am�w��pd���{Cn��A.��Zr��6�t�ֱ��)��6-��H"@k��I��1v��դ�*�ɮ�x�����!��b���q�Oݖ_"�䪥)w��a4����XL�V�����^!��%�_��O�˖jv��
ڍyy����^h�a^��X��XD����"����f����`lӵ��էHQ釪Yd���	���_)&�o�w�,zƢD��
�B�uSV��e9Q0E�������ωK�_,���)��XXv�Ɩ��4#	��|����_ �p��/���u��o�J���m���D����A�'��hDX��,.�X���&b�v����D�r����b[������`��-T�i6rLDZ�A;�M!䙔��9T3-��n�[�p����v-����m[Z�"��X.�I�|�1��^�� �D����r��Z:Ii8N��� ��V���
MݣrLS���<���d�i���H�~	O>]S�aS�hM� �e5q�kZ�yo<�F�����T�f�SlSwI��D�w�������UW�Հl)��mZqWo�@�|�4��7XC$�xX)h�ncCņ����P�S8�}iHj�~�yY|0�׮�����'r�e�����re���I�S�t`^p��'@����b��0j�1O��P�52	!�!;���:�Y�ev0$bd����ᡀ�
َ�~���`�~k��J�j�(�����bM�`A���X�{AH0G`�a"v��2��ʇE�G�%
���������Rfj0ƙˣ܅k�I%��o��j!Jj��%i�̠��V��$6�m��@b�b
m����>�O��6[p��MkD��=X�I�=��;2�<5L���L[��鯏�X�*�hwb��ޣ2Ҿ>�0}s4��Kr�;VX���'rWsh!"�j�מӀ��p��Rx�=бlcdc+�64��Lj٠��e����S:8я�66f�V�(�9K����P�@�A��'��p�^�މa�Jq�s-�&<����*8��/����^Ӽ�Z��x�Ls�tl�
��^.�_+LY��@���_w������r�_,��n���þ�'3����I�����B���R�}�:�6��K�Xc���1v�-���h�e0i��cZ=&�-n}�lw����d1{P���&���_}î�;k�#ȗkD$j+����H�b6��0],e����.�V�o�! �F�acglt�m���Y�?#�Kh���gc������X[�a��rU�RY*�ߗ���~�|��ch�d�E����Y���J�Jo�WbZxk�Oo�@����5� ��޼A�So��Z�{�	�-�u����ᶪ�b����*E<)K�dFE't�oVd0�.ِ?���h!vrX 
;>�دh������X&�S�g5�e�	�+�?$\l9�/ ����^5���~9���'��*n�By*�Yfu� /9�|o܅��g��+R�����l9�� ���0�M������E���?��c;'F��4:D�Q  �CM;C�������97L��	�i~w���q1n������řk̚���O��(��#p<�/�p����R���.������r�_L����n��[���e��:j[������l�v�!.x w�j�r�E�Q�7�TL�l���e?����m��G��R�u���}���`��g;��H�HO�F��"z����J��"Q�6�B.Gz� ̭���Dޑ3M�Td�I9�yb�P���?����$����	1�B�k��Þ@��
��ɺ�i��.RL��ce@=�8s&��w�x�`t���6��"4cir����<�Bf����d�7���r�_�?��|%��g��q�7��4|t�Y9>�� �"�G�@����ڤ@�r��,|E�����]
���w��t��Z+rs��V��2C�A�'��� .����l��U�aN����'`�`���z�^�Yӟp��nH&�F~4:zI6�#�����/Qo#'R��@�O�ߐ�m�@&��.���U�g^|�E]�yO6 �s��
��#Aw#�\k%Ӳz�2دN,��v71C}�6�b�����khHnp���Q6ۋ��|�F�c��Պ=�k3 �ə�X%�f���	��n�$�\$�N+c�1#��'��	ձ�]�r��F������g��Ϡ�(���L�7�U��Q��{�)��x4�X�?��.�0D୶�
Q��a��f�9]R�w>E&��cw&�D���T�4�:�gr��cbk��>-�T�	����,����R�c���_�A����@���W��{��^E�r�^���җӝ�~��_ ]B���O�1Zv;�"��������6]r��\2��sP�J��������
�^�1�CS��!�v@S6�s��E�&�9��d!�+�/W2A�T�&��|D���E�5N�m����FהHuC�G�0&�J��)����FL�W��,��HD����L2],/Dj[�DW�C
��`�hP�p���0���K�/TA�H��َ�U�N���D��Q�	��5�!P�h#��z�I����Y��JzC���S#�3!W��2!�֢��J����ӧ?�dڥ�Y)%XV`�Ɔ��,s�O�/����7OP�,�O�L�	�^���`�o1�Զli��:�B����|̞��%c��Q��x�����qAA3�E'�?�������x�w��4}r?\1�=pj�H��a>x?�ː��L�	�;���Ҟ2`xm!"�gaɣNn�jȯ�5ܯ=s�n�j׸d���w�nr�(����Xp�X�#�����м�F�:8+���>�% �k����í����<����|��-�?w���$�MOA�l��7<��c���^�/����yϼ������������_��0����W9%�5�W�H\�Uke#�֪q!"�d�q$�W��"G�b<�Wc�P�ŕ����˷�$�i�_����m���!�¬|��Y�V}��0IӰM�����W��Y�`����뛕�|3N�߿��!�e~O�t�^���~������}��9��y��ZyH;H�)bm:��'�q~�?o'���y���½����an9�/>��;���1c���D�E���"�����A������THx�e��qQ�a��k�?h���/r��:�=Z�0>��Tv�%g�Q�R���ʼG7�BP�`G!�x�@"���#r>��d�R9MS��l6�}�LJJ�.u�	��-Jyw�8�?視�v�|��tS/t����y�=?�Ҁ�U��{@AjnK|%�h䒇�����TL��@��l��m�U�r��Y�T�xyJ9uyZb����2�g�e鵇a������y�=y�hT_'쓒xZ����${8�rZ�7�{���ݝ��ϕ�n�4+��Yn���H�)M��io���D5W����q�P�Nw_V���4�]2��-[>:�(-�}\N���g��[�"d�l��w|$�ʯ���t-��(������|$J�F�$�x;�(�g�^+ߩ�'В��v��a���ĥzz;���w�;������Y��o7�J�ܡ�׉�_kǻG��MA;˯;�^��0�+�cyW���jI��\�$v��6�X�Ω��I$�ۮwwO���^N�@_��j��N����;���#m�S�%��FZ:��\�&�R��B3�ܕ���u"��D6kXŽfw����������Ds��J܁Q��$sP3����ե\����{�}k$����1�l��q�(j'�c���K�Q�{�$�P=[/��Q���S͌�n��l7��������΁�i�d$��JQ�zk�!�Χ��{yyC��F}O3�4ǌ��t�����^�8��r0��=�<cП�-�tn����G������h�O]�%,��g�����0�/��#v���v��4�1��n���,ݴF'���Ll�B��q���^b��Bq�Y�>fN��C�Ŀ���#]��V΋�Cp`r%%�hu�v��/�s��yFNƞ�FZI�|^���L�Y��bO��X���Z=�82*���,ȊJU��^j���N�f.���|W+��[��y�� 1�g��|D�|��HBB��� ��Ob�u��y�$f^'���Gb�u��y=$f^���?b�u��y�#f^爙�1׺F_xL�]����"W�?q��->���V?u՗������i����?�Q�����&GݿL�����v]R*l��TPR����c]+�IU�r�U���l����V�1c�gN2�f+n��{�)��)��m~ww�y�Nː����uϸ�Nۨ��rJ�om�:p��}�V���G��ȭ�`O��[�g����o1�|��b�	J��E�ⳉ���A$�:*�41j�yB��R�{�ko�Y^M��&��� 1p ��}/uߪ�,
��i�F#f���^�B-ِ�䪤��S���O�F�!/��_℞��hP��>{���ْ5c�������M(��6Vh/�0�W�H+�*��.A%S��6����2|��i;޻���s��_�[�b�� C�/�C��:����Ώ�������F�b�K��Ӡ�:�IrU���H��怊�!�N�3���Z>=o�v-:��� ћ��K`ԕ�0e��2����i�G��C�M $H�,�G�D�˱4l�4�ô�m�{���tMK�����dB�zZ�\܋g�ܠ�O~�J�udˆ���tzp�N��4���t�N����B(���W��m��	6�������8���<�/�#.������6Nxs��n��"د��e~y#�򒽑��n�*����m;��B�#t�0����!)�P�y�#�m2�:X�lh�̶��_3MH�Z^��=�B�5w>����8�
1�-�bb�s�� y��2�T���{�G��ff���v�·�]L��vf��O�-m�3m���o�\6�R���r��r����A�!��H���� n �!�����
����!n�""?N�\���i*FS]���~��=�F\�A��]���9���c.������m2��:��X	z4)M�����Ѡ�+���O
i��Y*1-k~C�{���Ы�CƓ�fc��]ך�\�%��*�I���҇��\�A�(��X��Z��}p�0Cҟٞ�
Ț��L�X R� X�o�`���F�v�c�pb`P��̙�	LE1g6�"�+�q�	���|x>K�"Y��%]�j:���eY�x�8: *J`خk��P��4�^�0G��qqo��}o%����ǩ0cM2��Ց3ߏ?��p�>������ȩm��b7ߟqC�l�K����c �%UEvݚ�P��p��M�����Hh�1
bza���T����I���ǭ$��x��Y�'�������_�;������������O��?>��o=���	���-�߸���/>x��O�[�W��5�b�P?�^*��&UM¥TRͤ3����&����ҸL�rTJɑ�FeU�$���͑j�B�r�A�����?|6�����4�ɯ���?[��O�?��I��p��x�w��?����~Ea����������"��o�~���w�x�_���	�z����>��������ͱ�����x���k�[�k�l����\I�쓶˰��맃�I��h��	��W��u�c,rw�ū<��9E`,�~y!�]��a��Z���M
'݅pҠ����^^#�Ä��ȯ�w��i�P���yC�9w�v;�Io�[�#s 4�n�F�J�K�`)�9.�Qu��չ��8�����S������K���E�a1nQ=鶨��pP�$��2lv8����AyɌ��� QI�\�r\�;���S�mvbڦ�ЅZ��i���26X
�y�8u�Z��N���@����M�N7J	�k�G�EW�e0?�-bL�A���
�^�Kû�=Aw����(9�i����p3�>�NGX�L�+��7�#kY鎇���4�m|�6�&�����$a�O�+q��`�\֤V{F�����T�V��:���<_<2�6���V�i��q��O�X[8��?�Dk���J\pw��.��;��;����Q	�u��V�&c���T����J��bg/;��H$�9�dE���n6���Y�C~!bg����+ʞ�#z0�)���=�=�=Y�����=\.]O�`��9�W��l�7���,�`��^��&#��m�di����ȡ*��M
Ge�8�p�çS����5]S�Տ�iM\K�S�����ϳ��LϢ�{y:��%,����Q���T�&�'+�P2*�v��Ʃ{���Хy*W#�Wȥ5b��tʭ�L�u�nG�K*锳5���Q%C�Y�Z�W��v�]�*uL��������<�qPY�`7>�}7�K�^���{��ҽ�
_���_X_��z�����j�/���������M>�j�����{���b���?x+�K��5	�y�r8�X���˱�b/�8�Z�߂�EY����ob�K��O���O}�����~t?�����0�/.ee�`e��������D�`�LgY�2ͣ��W��|I|�2��ҭ@���m�W܂�XXΥ �#΅]Gk��8v�9ʹ0�u5\N�Y��ls�#�i��oTC����i��_X��Zp�B{�F�pZ��"
��,�O���I]+�4�\�����܈��F8/wK{���������#YS�I�u�mg���ѨP�~R>�����t��2Y$�X��G2�r������4Kף� #Ґ��B�����3�̭FC't�n��{�ýLƑ��)�@�%�-��A���}�mJ�Z�Y���8Җ��QQ&�A{4:$pQ;ʤ�G5�A�8%'�h�v(!� ��	n7�>�0cm�2���|\��'�TB����.��`x�>��.%�<T��PQnt�	�o�¬RᲕ������?y��-0| �+�
raE
2;����TŤ�X�K
lwY=�Uv�����<6�sO�J@��u�= w��'t����
C�c�ū�p,��\���ձ�N���uɬW�d�h���a�m��-�ZI�;F�=�:�MaL��9=�9����:m�uz�5�'�D�J�[��jU��"\���e�S��M���0���[��-����J��n�g{���� ��E�H�}���bY8#�[ `��hA�(GٺV�j�Rg(��	Wne�e�I�yw$����h6E@0:+���R�?̗���}e�t���2NघoPV��j<y&���.����r-H��|Ԙ����L rLEHI�V����
�-Ҿ Y��Į{#]$L����[��
	l�a҄�| P���r��*�����r����i�U�:u`vF\n�����t�Cf�F��In�'Nɤs�n5A1N����v�:��*;�Xv5�B�r]��e�@ɴ+]�4��4N�+W҈�=vzy�(5���\(�J)�$nq�P�0�b�����TC^�J=��=�>:�-��|��L����v���NH��Zt�4�]�I/��
�q	6e.�^O��Z5֬qS��&�z��o�AD/�z쵨�V"C���u�k��ʕB�W���.��lgjx�b�{A����<<������-�z��e�2���C���Q-c��ވ�z{��ӧ��O���2��^CeD�Q^�뱗��ȵg���o0��P2��!�y� ]ћХ^��yz{�$�c�Ӧn@�T�1�e��|��"+9�_���8gS4u���o��y�uqhU�j���1*� {۷}�^�#����E��Y�����w�>O����'rW3�E��?<�<��'E����n#݌�/�F�<�ڏ�}���_����k�����[���FF��P<5> ��=<Ȳ}�0����D�J#�A��-?����M�,6�������0߰	Q��c��5{p��v�0}�����/�gUao�]�Y7����iO�5rͺY��e�Y�����r� =����;��E\ ��kO��M!u�3	���G��b��3(�!C�ZKf�w�-=�AhS����j���Z�L����Sћ@��i�����c��q�1�g(���BE�G'�8���53��X2
v��D��̛/y�< :_[�!�*�0�X�y��(���x'��O�������,jџ��"�m,��I��:2�k�5AF��xnL�1�=��a�;�Ƴ�u�H�*�ň����z�A�BQ�O֘���5y�?'�3���V��F6p'�ڏo�ұG��l�ʉv(��:�I`T�eh��{]3�֧�X1&��oZ ��	��֋�_��������K&�
1��<����+k
�lq�w��6V�[lS��� � ����z@2�l����/��-��}�����mS��4\Zk�[��a*����[���rhH��ـ�Y�Q�g��N݂���'��I./���Х�Ʒ3GP@a6A�)?��-yլ)�9a���O����,[�
��HOS
y(�}A�g���g�tZ�k�J����2l��az�1@M��!<�x�lz��P��N�&�`��p˽��G��6�Aw�)F�?���+���'b: �ӕ'�0�����2���D�B�㤽	�@=k�L-��2��.� ���h�����"-�W7j3;��h6��  ;Ѧ#0h?�=bn�!���h���v�,�t�${s�mW��`���쭣,�zmjH&����c��,�o��7���&ڻ:Ҿ�Ö��M�Ͻq:�
��up����x�j"h�oY�DD��d��^��|��]OE��F ��GZf����a�������H8b�C��@՚�����|}ō[Φn��Ŧ	2���9<G�9E�q��]���E�[�xLS�7��e"4_1F�n�'��0�ך}���)?w�%"r�vD���#�;��{�v�7��ѱ^q�o�����Ά8���K��Sr;�3�L'���n#�!�����cDC�1�<^����_! :,���Yh�����1���$�9Jb'8'wTlq�C�	�� Ď�b�\T^���_�Z��zaC\��ڑHR��I*-��$S��ITRKR�t��(Z�P3}B�H9	�ϑ�ܗ����Je5�LK0�-�0(�"���[^�-���rZ� r}�?��r��G/��UG�cA�	�`�峁$r���$Y��TϨ�J�ZJ���$I�t*�e�l:�%%Y�!��$��lNKe4BJK���#ً���~N��#�o=z�H�L��g���H�����_?<��Nn����;��(x	��5�F��&�5V�*פ+ǕZ��r�'�&����-���,��Z�'8Ү�sK�[|K��R�}���/)������s�]0�<]Zu�}9��4�tx�0�?��\����ȎUx:��&NB��Z*	�p3��ٵ�$��A�B�[Fo߸�=�>���tm{�c� L`b�	8�����w����S�GyX�j���59��E�Z<�s\s���|����.���1��f�Cᘫ��_����b?�H�w։�4MLgc_�zlG�Մ�����(Z6��sf-m����@�R�%�k�_<�rb��<��dt}�����x�g�\z�Kgiv8$��"pl�m�0�8���"��-�Iޚ)���|��ΗX���W0A
����T.�z��m	�(�y��z3��/��v	���M����u�D��8����
���&v#�n��Z�k�����f+���jm������Gm�7% 3
�c����]�n�gk�!���p;b��v����
+%F<*:��~������v�8`p��l�RN������9��,��h��?��������|z���G_g��d:u�������)��o����m���Ǵ�:a���-��X�k��4y��o%}�?I����ʤ���m�������W_�4|e�m����Q���������t���͝����&�gJ_
�����N���t[����$��kx�g�*xG��U���M��\&K(Z:�g�I%Ie�r&��d\Ո))��Ma�W;}���4qF�K���������$?s�g����][s�h׽�W|�V���[�rRA���W��(�
���_M:�3�3I�;@w��J�2�Q�z�^{�����6��i���i�����n��z��Y������Q�3���gv�tg'z�!��1F��6�x����I��������lu�ƣ�2�Jc���ԋ��r�&�?���k���&����ׇ����ِ�_'�1�x����q��*��'��?	�_�������z �����w�}�����Q3��&��~>5����k����@�W����*�m\����_;���=�3��U�Y���#�_��U����Rs����� \�	Wu�U������0�	����/���P�n������?��+B���Ck@�����!���V����?����)�����V���nHg+���?�Z�?]L_�?���'�#����!zW���m�y��gQt�of�����ϗ�Odm83en��Zj��.�f��/�>�).��~��4�̍��Ȼ$K�\hz�d�m�}dY�������)������{}��e����ώ�'{6S�.�+G[�{����b�R��T��?ۮ�ݞ�ǽO�rX����ř�Dz��y.��V�w�C+�QR6�Y�����v�I�Ќw�XN>:[N8�|����ASw�� �B�ƙ��n�A#���kC��ӂ(X � ��ϭ��������H������?�p�w%��'���'�������U��/�#��P�n����l���i��*�(��CP� �P���}xu�߾������>����!4�L�!��o��og?���\�)�w2���?���k�����ؖ2��'�d1�=����mT!<���X��1�����
���jT�R���vߝ0j0���v���dOe=���>t�x��� I�B{.�W�dj*���������Ʒ��pd�KA�b�[�F�}Z����4�Ζk}�D���b�ba`�I�8^x��1w}b�ˏ[j�l���K��ӱ>�3�?0�C#��@����@��:�dyz���P�n���'��,<�A��4���g������4G�Gc4��!R>�A�ɐ��0M򤏅���h�?���������������m��diƝ%�m�E��O��ߑ����7��'j�<���8�]^ќ��;�Ү�̖}������)ئ�͖�����Q)�,;�!6����ߡu��vtV�y��ߊ&����Yj>������	�?�����?�������q-�~3>!���P�Շ�Y�S����:m'Y��-a�3κP���uWm�Yz|���>���ј��K������xd�.�EaŁ$�]
[G�(�H����j]�B�.�-ۚl
�Ȃ��TL�P�wi��ފf����5����~���W@�`��>����������^�4`h��c�;�GР���k��-��/b���#*�H�7S��q%Vγ��������R�������������<}�� @��g�p��Ag�+�REn� �z�`�)5r4m����tK���{X �V�^���ەeɣ�TD+2F�>�Me�bi����A:�{Uo�a��v��ܠ@"�|��&ї�p��{z��� �i��.^끃)m�*>a���'t�(�F�4e������r�D*��i2�r�L����\�bKjo�ĝ���GMH�8}����AWLIU����6�͏�2[����x����I��~?�v�j�bq�hh��"����T�R�|�O�":��N.k���B����p���@�U��?�&<��*��k�?�~��f1���M��듿����%���!ӯ�����3��f	��� ��C�?��C���O8��ׄJ��{>C{��c��so�!`�y�P|�bÅ���o�Ax$A�9>���/���C���O�迏�Ϝ�u�q]�;��m��M t�� �e����~L���S�I�_����Ow�2�XVI��t�v\��r�V1B�R��Mq�0BY����2f0���U����������Sn�>0rӆ�߷�	�?N=����J����x��U�	U<�w��A��_��̝������2ޛ������ ��?�����p���n�����'q��������o }��6����h]�ع�S6N�ub��e-�߲��+��D~d���=�Gf�o�l�_g��bbNF�7��ǝj�E^���9�,�xg}�l}��O�1�g�dE猼D&#�'v���d�&#g1�4Ak{s+�i�uYwWȜa�j�χ#ƥ�K'*��m�}]�:ȭ�+?g�ߞm7��0�-n�wdEU�è�.��~���@��&�=&zt����Tv$�#��De�� ��}{R�W��G�[���*ZۉS���4G#5�h�I7F�2O۩����y�h!ӱ�zX|�(�=�g$4z,�24A�]���[��p�{S����M�'!��&T��0�44��0����W	`��a�濡�����_�d`4P�n�����}������)hD�� ��`���������������c����ǟ����K�~��Ǩ�����'���M������
T������X�������?��]j���������?�`��%h �C8D� ����������G%h�C8Dը���7�����J ��� ��������a��"4@��fH����s�F�?}7��_���R�P�?� !��@��?@��?@��_M��!j���[�5����_���Q5Q�?� !��@��?@��?�[�?���X	���8���� ������������������M��a��>��?�����/]�������W����%��C����s�&�?��g��M���AY�_`ˑ���pP>�A�W�`���$�α����E���g�	�}��'�����8R��
��4e�R�w�׊S��
T�`�w�L3�0���E-�Q>^���1f����L�䔴�0(G��%�ˑ`H�0:���t��Nw�eۓ�V9�6R���0B��ڹ�#�B���v�]�G�r�u��h������/wm,܄��Lu�kiw���~��&����Yj>������	�?�����?�������q-�~3>!���P�Շ�Y�R�ϭ|`��V�!y����j8/G���Ƈ��"씭�����un��(Qjв��a����(���C���S������ufG�?�:�r�;w��p���I�а�HM=���j�Th꿷��������V�����Gp���_M������ �_���_����z�Ѐu�����������xM����:�?���Ii"��55�Չ#����_;����Y�ݤ�,����w���Dޒ�G���a���%�������l�GX�����'�������Nx�Ml�Q-EڊY	e�����%�G̎*�����L�r��&їw�����������B����)m��'�yuY`@xB��ahtNcQ�9���P,7��q�1�� 3(G��AWLI��g��󲾼�?��d����COcds�݅u<�N�jB,���ķ|�KU|���5�"�v�)�
�{r�.�;�ݛ��}w~����<<|{|�o|�cq��V��x��^���ϟ�	x���	�N=�����J���O�n0��XT�����)'���@������/�_����\O��h�����`����+'��W^��[����k��n�6�n;�٣��b��H��W�����h˂���!�6KӢ����_��+M�����w�'�y�/����3%���-�o�KO��rt�.o��-��kl��l1
�8����u�E���Y�-i:�@�v��I���i-�l��t��N�2a1!��kZjD(e���^"���@i1���8N:^vȤ䎧���!Źbj��-�d�=�o�쥝�\k!F3��� ��y�a��-�����gb.Gf,J"��g��l��~[^���maF��5��*$΁|@��w�o\���
���H,��ŉxD�h�?qz>��-L��y(�6�t��V+R#1vPO,��;z��E望%�*�L%�u�	o�d���������?��V�j��Ә�����_��]�M1������,K���#Y�	� }�B,����QhB�?���a�������B�͏�0�Cw~�����[���g����KW����˕���=r�V`���������������U�&�?�%�������p��*����s?�G���������y_�?5�N;�š8�
;�2�Ep��yv��_P���)����6�}����q?�G�������������^|��y��g�qnuM���]��HL�%�a{e"<3�&'m�opc��T�m�l���2`i�A���٥��[L��݋bu��l?佾ߋ�<��<_)7�(�Q,8�NK�X6�:�^P��E���t9�ٺ4��'���N;>n/��f�cv8e��tp-Q"��Q3۬�"@��o��A��2S^��R܆K*	[�i۟�����X�ᢲ�������	��x4����������
B��p�\pq����+�Å���q���νIMmM���)��ԩ3�I�E�fO  x�_��r �(����6݉f���f����JbDP���k��]x�ň}��DФFt�Q*���I�������c�o�o�������ړ	�!�Z���c��81W����>^�Z��u�`T�����ۖĵ`?j[��ﵼ�������?�,B�_d���n������� ��_Kra��L���Z���:R��s�i�����W�?KB��
�������;��(�u�����R�ػy�������?�r��P�r�G��/�>V������i���ƕ�XlT&��B<6+�cs���S��U>=b�2r�����e�
{\�r�M��!��>Z�:��Jxa/�<���i1g$�ý����69����9�V:��3��B~9r:���e���n��Qw=-4�m;J�sK��X�M��M��fCn��2�����?
��j�q�/t"e�٣��Ao�N�Rl�z��+k�gG�m���ac$?�*C[���U��^��nG�smW3ƥ�)O��Z-���'�=v�b|�R����6����sgW�TI���R�:��r���P���R�	��zSRO�r��?M�qk�o���
i����V�����_��BG��A�G&�����l�S���O��	�?a���[���9���I ��o�����t���P.cd"������0��
P��A�7�������E�^��Y_#�����
��?2���U�w������մh2�?�?z��1��S��'���� ��G��$q5��J	��u!����\�����i�����HK����C��0�#������K&�~���?R�����@���/�_��� �?R"�!��D�U��¡�C:@��� �������K��A]�@���/����Ȉ�C]Dd"������0��
P��?@����v��F��I��/pl��������eB���`�W*dC�a�?*2���d�������L�?���D��K��߄��߷�˂�����H�L���a�z��њQ�H���V�4)��fV�D�&[2	�b���Z���L���Eg��[�ty���E�:������"�ow�a�j����U��ߐ��V�5�r�Y�Gb���HK�:�aNk�9u�xE?��	�KMF�[^�d�Z�t��7��=�j�.�W���j��Q��d��JAajk�E�XS0g*��LWS�ފ��NۖĐ!\^��ű�m=�.	�Q����%^�T�9޻:)�<cd������@���+��Yh�!�CG�������?�!Q_��%��:~f��kv��wR�M�
c�"���ʆ鏢�m�&-�݅�bgOz���&��Y��_�u��t�^���&
;,�`�_K�~�c�բQ�֬�L�x�^Cy9�.ԑ��ȥ�ۅ�h�|W���d��/B�/"P����`���E����_�������/����/������< B2��h�������7��=��ֳ�k5�З���h]+?td���/����O�χX�%~*���������6�eo�+��tG��Vow�jo3��ᬥ��<[���(?��Q~��5�N��W�-�F��5\���J�yE���*��v�۴X[�~�ਲ਼;;O�O�J	�T�٣�����d��-J|Ǩ<�)D�����^��`��D�D�����Z�������^x>%�|���NMg�ё���ʤF����<�ו	���0)���)R������b;N�QP�֐��݁a��!�Z�zиn��|/ɂ�#h�����n��^ �=2J�������E6����oO&�����ł��Aj����e�?h����Z��o�z���O���$��� w�?�?r�'n��@�O* ��������?�?r��n�������%��*�铖�_��X�)���P��?B���%������/��?X)�߷�˄����Ȍ���H�D��\�����
���8%��s�����~��m~tl�lw��,�*�C맛�aDR�)�#�s?��
��r���ɇa&�#I��^��;n��K�o��{���^���):a���O�Tew������6�E+3mj����k��Z�>��5ޞ:���p�Z7�����0���d�N㵤ڎ��$��Ѽ�K�/v#�W����Ṃ�pK��<ˆ���r�}8V&Ro3q�dy�j���_���e{,�D>X���7�,��ak�^��� 2�Z�׆�ZyxЩXDaλ�Z���ޭ���J������Η��a�	����@��^,��Z�#�߷�˄���?2����� U2�ߨ����*@�/�����������D �ϋ���w	�����2��4������W@�[�����#�[�����Q�Qݎ6��<���+��j��7ƃ_j�_������{��7�ݕ�/i
��=��S@il����Sm����ZI�hF�a7�:�z�^C�&Mr���b�
��7%�r�'Aw�(�Ґ�"��B�X��>d���%I & K� �(�qQ�S�Qm���E��
�����ܔW�f[v�����ns������tP^7��@��&���^S��0���&�[c�ӌ���ˇ�?L&�qc����
��ߧE�Q_������Y��"q��c�?���T�b��Z�Z����"�����4i�$^*�4aX���E��2f�Ē3������W&�k�O���?s��>;e{���d�'l(�>�ԈŰ���nK���9	�������q3&���7<_��nz������&/i%�{vQӚ��LeN%��/N��:Y<�F��4���sL ����a��ג����i��,���9Yh�!�CG&��� ��?-���/�]����?3��F��h�������U
KJ-���k�C�Iv&�������LO8��AKz�W�j��K�
BD�k#��cO�c�8d�*�/̎M��+�}O5Ö����B{�	��:Z���R$��%����/:����ۃ��74X !����_Ȁ�/����/�����(���!�������-�7J��-<����𘑻o[2�/F�`��WS�����)�g����.���/�`��D&�jZ'/8��W�(h�����˹d�M"�OelY(�i��������R��u��z��U��i��m��/O��<,�y��E�Γ���U�E���\��	2�H|����n%��@��_�5�T��p��%Q��oY�b�9��w�0���./�G�Q��f9�+á?7���i���/b_�I"�uq�m�j�lz�!�C�������Ǧշ6�b���:F	��_F9�ϙ=1ڋ�!���Zujwf�	�%��2��3�߭��Mn����=��׵�������g�ORL��O�ssn�n.�c�Zh�><5�=|��?�u��o�9�㻊�Q��m�_��}{T�ί��>x��rVfNx���VA�?&p�܇�.�v!����ç�����AO6�������+�7��z�x�S��d���]+��e��3ټAߘ����]J�[���}�7���|�{|�$�$�������t�-�Z0ǰ��ă�6n�r� ̙������|�s�j��1k͝X`���>~O�M#��FN�h�����k�j�XN��J�,����f�����o���7��(��޽�GΘ���o|���<׫~�]A�_��~���w���=�E��Q�W��Is�X0�{�|W�>X��}������5��*~[�����܇Yr��_Bk��G��W��6����Ʌ�����q-���:_� �c��w��vn+���r�3����}���>���+�5����+�O>�ݭu���4����z��X�2M�[�;k���zR��9��`9�4}�a����x�����s�y6����8��Z��'��`�Fa�|�
�F���'�n�k�_�'���Y|�cB�+~l�b�c��ZMI�۳��HrvA���e
�����^ua��~п<���                  ���+�a� � 