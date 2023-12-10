
from web3 import Web3,Account
import sys
import random
import os
import winreg  # Obtain the system's proxy server setting information
import json




def extended_euclidean_algorithm(a, b):
    """
    Returns a three-tuple (gcd, x, y) such that
    a * x + b * y == gcd, where gcd is the greatest
    common divisor of a and b.

    This function implements the extended Euclidean
    algorithm and runs in O(log b) in the worst case.

    """
    s, old_s = 0, 1
    t, old_t = 1, 0
    r, old_r = b, a

    while r != 0:
        quotient = old_r // r
        old_r, r = r, old_r - quotient * r
        old_s, s = s, old_s - quotient * s
        old_t, t = t, old_t - quotient * t

    return old_r, old_s, old_t

def inverse_of(n, p):
    """
    Returns the multiplicative inverse of
    n modulo p.

    This function returns an integer m such that
    (n * m) % p == 1.
    """
    gcd, x, y = extended_euclidean_algorithm(n, p)
    assert (n * x + p * y) % p == gcd

    if gcd != 1:
        # Either n is 0, or p is not a prime number.
        raise ValueError(
            '{} has no multiplicative inverse '
            'modulo {}'.format(n, p))
    else:
        return x % p


def bits(n):
    """
    Generates the binary digits of n, starting
    from the least significant bit.

    bits(151) -> 1, 1, 1, 0, 1, 0, 0, 1
    """
    while n:
        yield n & 1
        n >>= 1



def positive_mod(a, m):
    a %= m
    if a < 0: a += m
    return a


def gcd(a, b):
    if b == 0:
        return a
    else:
        return gcd(b, a % b)






class DiscreteEllipticCurve(object):
    def __init__(self, a, b, p, G, nF=None):
        if 4 * a ** 3 + 27 * b ** 2 == 0:
            raise Warning(BaseException, "curve contains singularities")
        self.a = a
        self.b = b
        self.p = p
        self.G = G 
        self.G_hex = [strToBytes32(hex(G[0])), strToBytes32(hex(G[1]))]
        
        self.H_hex = ['0x06e120c2c3547c60ee47f712d32e5acf38b35d1cc62e23b055a69bb88284c282', '0x16932a2d5a8000de7a60d3fa813123776d3b01d3b0e0c2ae8cf09303d04fc4d7']
        self.H_int = [int(self.H_hex[0], 16), int(self.H_hex[1], 16)]
        
        self.PublicKey_hex_list=[]
        self.PrivateKey_hex_list=[]
        
        
        self.P = (0, 0)
        self.R = (0, 0)
        
        self.know_nF = False
        self.nF = 0
        if nF is not None:
            self.get_nF(nF)
            
    def setKeys(self, PrivateKey_hex_list, PublicKey_hex_list):
        self.PrivateKey_hex_list = PrivateKey_hex_list.copy()
        self.PublicKey_hex_list = PublicKey_hex_list.copy()
        

    def get_nF(self, nF):
        self.nF = nF
        self.know_nF = True

    def __check_on_curve(self, point):
        return True if (point[0] ** 3 + self.a * point[0] + self.b - point[1] ** 2) % self.p == 0 else False

    def get_scalar_multiplication_hex(self, n_hex, P_hex):
        n_int = int(n_hex, 16)
        P_int = [int(P_hex[0], 16), int(P_hex[1], 16)]
        R_int = self.get_scalar_multiplication(n_int, P_int)
        return [strToBytes32(hex(R_int[0])), strToBytes32(hex(R_int[1]))]

    def get_scalar_multiplication(self, n, P):
        """
        Returns the result of n * x, computed using
        the double and add algorithm.
        """
        assert self.__check_on_curve(P)
        if n == 0: return 0, 0
        if n < 0: return self.get_scalar_multiplication(-n, (P[0], -P[1] % self.p))
        if self.know_nF:
            n = n % self.nF
            self.R = (0, 0)
            self.P = P
            for bit in bits(n):
                if bit == 1:
                    self.R = self.get_three_pionts(self.P, self.R)
                self.P = self.get_three_pionts(self.P, self.P)
            return self.R
        else:
            self.R = (0, 0)
            self.P = P
            for bit in bits(n):
                if bit == 1:
                    self.R = self.get_three_pionts(self.P, self.R)
                self.P = self.get_three_pionts(self.P, self.P)\
                    
            return self.R


    def get_three_pionts_hex(self, P1_hex, P2_hex):
        P1_int = [int(P1_hex[0], 16), int(P1_hex[1], 16)]
        P2_int = [int(P2_hex[0], 16), int(P2_hex[1], 16)]
        R_int = self.get_three_pionts(P1_int, P2_int)
        return [strToBytes32(hex(R_int[0])), strToBytes32(hex(R_int[1]))]
    
    def get_three_pionts(self, P1, P2):
        '''
        :param P1: (x1,y1)
        :param P2: (x2,y2)
        :return:
        '''
        
        if P1 == (0, 0) or P2 == (0, 0):
            return P2 if P1 == (0, 0) else P1
        
        x1 =P1[0]
        y1 =P1[1]
        x2 =P2[0]
        y2 =P2[1]
        
        flag = 1 
        
        try:
            if self.__check_on_curve(P1) and self.__check_on_curve(P2):
                if P1 == P2:
                    member = (3 * x1 ** 2 + self.a) 
                    denominator = 2 * y1  
                else:
                    member = y2 - y1
                    denominator = x2 - x1 
                    if member * denominator < 0:
                        flag = 0
                        member = abs(member)
                        denominator = abs(denominator)
                
                gcd_value = gcd(member, denominator)
                member = member // gcd_value
                denominator = denominator // gcd_value

                inverse_value = inverse_of(denominator, p)
                k = (member * inverse_value)
                if flag == 0:
                    k = -k
                k = k % p

                x3 = (k ** 2 - x1 - x2) % p
                y3 = (k * (x1 - x3) - y1) % p
                return [x3,y3]
                            
                            
                
            else:
                print("ValueError@@@@@@@@@@@@@@@@@@@@@@@@@@@")
                raise ValueError
                
        except AssertionError as e:
            return 0, 0


    def add_hex_mod_nF(self, n1_hex, n2_hex):
        n1_int = int(n1_hex, 16)
        n2_int = int(n2_hex, 16)
        result_int = (n1_int + n2_int) % self.nF
        return strToBytes32(hex(result_int))
    
    def sub_hex_mod_nF(self, n1_hex, n2_hex):
        n1_int = int(n1_hex, 16)
        n2_int = int(n2_hex, 16)
        result_int = (n1_int - n2_int) % self.nF
        return strToBytes32(hex(result_int))
    
    def hex_mod_nF(self, n1_hex):
        n1_int = int(n1_hex, 16)
        result_int = (n1_int) % self.nF
        return strToBytes32(hex(result_int))


    def __str__(self):
        return "$$ y^2 \equiv x^3 + {a}x + {b} (mod \;{p})$$".format(a=self.a, b=self.b, p=self.p)
    
    
    def ringSignature(self, random_sn_hex_list, sn_hex_my, address_fee_len_hex, kH_hex):
        random_sn_int_list = []
        for i in range(len(random_sn_hex_list)):
            random_sn_int_list.append(int(random_sn_hex_list[i], 16))
        sn_int_my = int(sn_hex_my, 16)
            
        _account = Account.create('Protocol')
        a_hex = self.hex_mod_nF(str(_account._key_obj))
        
        c_hex_list = []
        for i in range(len(random_sn_int_list)):
            if sn_int_my != random_sn_int_list[i]:
                _account = Account.create('Protocol')
                c_hex_list.append(self.hex_mod_nF(str(_account._key_obj)))
            else:
                c_hex_list.append(strToBytes32("0x0")) 
        
        GH_hex = self.get_three_pionts_hex(self.G_hex, self.H_hex)
        R_hex = self.get_scalar_multiplication_hex(a_hex, GH_hex)
        for i in range(len(random_sn_int_list)):
            if sn_int_my == random_sn_int_list[i]:
                continue
            kPH_hex = self.get_three_pionts_hex(self.PublicKey_hex_list[random_sn_int_list[i]-1], kH_hex)
            ckPH_hex = self.get_scalar_multiplication_hex(c_hex_list[i], kPH_hex)
            R_hex = self.get_three_pionts_hex(R_hex, ckPH_hex)
            
        
        c_hex = self.hex_mod_nF(keccak256(address_fee_len_hex, kH_hex[0], kH_hex[1], R_hex[0], R_hex[1]))
        
        
        ck_hex = c_hex
        for i in range(len(c_hex_list)):
            ck_hex = self.sub_hex_mod_nF(ck_hex, c_hex_list[i])
        
        
        for i in range(len(c_hex_list)):
            if strToBytes32("0x0") == c_hex_list[i]:
                c_hex_list[i] = ck_hex
        
        
        s_int = int(a_hex, 16) - int(ck_hex, 16) * int(self.PrivateKey_hex_list[sn_int_my-1], 16)
        s_hex = strToBytes32(hex(s_int % self.nF))
        
        return address_fee_len_hex, kH_hex, s_hex, c_hex_list, random_sn_hex_list
        
    
    def ringSignature_toStr(self, address_fee_len_hex, kH_hex, s_hex, c_hex_list, random_sn_hex_list):
        return_str = address_fee_len_hex + kH_hex[0] + kH_hex[1] + s_hex
        for i in range(len(c_hex_list)):
            return_str = return_str + c_hex_list[i]
        for i in range(len(c_hex_list)):
            return_str = return_str + random_sn_hex_list[i]
        return_str = return_str.replace("0x", "")
        return_str = "0x" + return_str
        return return_str
    
    
    
    def ringSignature_str_split(self, sig_str):
        sig_str = sig_str.replace("0x", "")
        address_fee_len_hex = strToBytes32(sig_str[0:64])
        len = int(sig_str[52:64], 16)
        kH_hex = [strToBytes32(sig_str[64:128]), strToBytes32(sig_str[128:192])]
        s_hex = strToBytes32(sig_str[192:256])
        index = 256
        c_hex_list = []
        for i in range(len):
            c_hex_list.append(strToBytes32(sig_str[index:(index+64)]))
            index = index + 64
        
        random_sn_hex_list = []
        for i in range(len):
            random_sn_hex_list.append(strToBytes32(sig_str[index:(index+64)]))
            index = index + 64
        return address_fee_len_hex, kH_hex, s_hex, c_hex_list, random_sn_hex_list
    
    
    def ringSignature_verify(self, sig_str):
        
        (address_fee_len_hex, kH_hex, s_hex, c_hex_list, random_sn_hex_list) = self.ringSignature_str_split(sig_str)
        
        random_sn_int_list = []
        for i in range(len(random_sn_hex_list)):
            random_sn_int_list.append(int(random_sn_hex_list[i], 16))
        
        
        c_hex_input = strToBytes32("0x0")
        for i in range(len(c_hex_list)):
            c_hex_input = self.add_hex_mod_nF(c_hex_input, c_hex_list[i])
        
        
        GH_hex = self.get_three_pionts_hex(self.G_hex, self.H_hex)
        R_hex = self.get_scalar_multiplication_hex(s_hex, GH_hex)
        for i in range(len(random_sn_int_list)):
            cP_hex = self.get_scalar_multiplication_hex(c_hex_list[i], self.PublicKey_hex_list[random_sn_int_list[i]-1])
            R_hex = self.get_three_pionts_hex(R_hex, cP_hex)
            
        ckH = self.get_scalar_multiplication_hex(c_hex_input, kH_hex)
        R_hex = self.get_three_pionts_hex(R_hex, ckH)
        
        c_hex = self.hex_mod_nF(keccak256(address_fee_len_hex, kH_hex[0], kH_hex[1], R_hex[0], R_hex[1]))
        
        if c_hex_input == c_hex:
            return True
        
        return False


def bn256_curve():
    a = 0  
    b = 3  
    p = 21888242871839275222246405745257275088696311157297823662689037894645226208583
    G = (1, 2)
    n = 21888242871839275222246405745257275088548364400416034343698204186575808495617
    return a, b, p, G, n



def strToBytes32(str):
    tempstr = str.replace("0x", "")
    length = len(tempstr)
    if length < 64: # 
        for i in range(64-length):
            tempstr = "0" + tempstr
    tempstr = "0x" + tempstr
    return tempstr



def strToBytes32_add_r(str):
    tempstr = str.replace("0x", "")
    length = len(tempstr)
    if length < 64: # 
        for i in range(64-length):
            tempstr = tempstr + "0"
    tempstr = "0x" + tempstr
    return tempstr

def strToBytes6(str):
    tempstr = str.replace("0x", "")
    length = len(tempstr)
    if length < 12: # 
        for i in range(12-length):
            tempstr = "0" + tempstr
    tempstr = "0x" + tempstr
    return tempstr


def keccak256(*args):
    str = ""
    for i in range(len(args)):
        str = str + args[i]
        
    str = str.replace("0x", "") 
    str = "0x" + str 
        
    result = Web3.keccak(hexstr=str)
    result = Web3.toHex(result)
   
    return result
    

def randomSn_hex(sn_list):
    random_sn_hex_list =[]
    
    templist = []
    for i in range(len(sn_list)):
        templist.append(1)
        
    while True:
        k = random.randint(1, (len(sn_list)*10))
        if k >len(sn_list):
            continue
        if templist[k-1] == 1:
            _hex = strToBytes32(hex(sn_list[k-1]))
            random_sn_hex_list.append(_hex)
            templist[k-1] = 0
            
        if len(random_sn_hex_list) == len(sn_list):
            return random_sn_hex_list
        


if __name__ == '__main__':
    a, b, p, G, n = bn256_curve()
    G_hex = [strToBytes32(hex(G[0])), strToBytes32(hex(G[1]))]
    
    E1 = DiscreteEllipticCurve(a, b, p, G, nF=n)
    
    k = 218882428718392752222464057452572750885483865758084750885483644004160343436982041865758084
    k = k % E1.nF
    
    
    public_keys_hex_list = []
    private_keys_hex_list = []    
    
    k_temp = k
   
    numbersPublicKeys = 12  # all publicKey include owner
    for i in range(numbersPublicKeys):  # all publicKey include owner
        k_temp = k_temp -100000
        public_int = E1.get_scalar_multiplication(k_temp, G)
        public_hex = [strToBytes32(hex(public_int[0])), strToBytes32(hex(public_int[1]))]
        public_keys_hex_list.append(public_hex)
        private_keys_hex_list.append(strToBytes32(hex(k_temp)))
        
    address_hex = "0x5a42D4902977327eA1977e303Eda61ca6e2647a9"
    
    
    sn_list = [1,2,3,4,5,6,7,8,9] # not include owner
    
    sn_list.append(numbersPublicKeys)  # add owner publickey
    
    sn_int_my = sn_list[len(sn_list)-1]
    sn_hex_my = strToBytes32(hex(sn_int_my))
    
    print()
    print("Signer's public key: ")
    print(public_keys_hex_list[sn_int_my-1][0]+public_keys_hex_list[sn_int_my-1][1].replace("0x", ""))  
    
    
   
    random_sn_hex_list = randomSn_hex(sn_list)
    
    E1.setKeys(private_keys_hex_list, public_keys_hex_list)
    
    print()
    
    print("Total nonces after transfer:", numbersPublicKeys)
    
    
    kH_hex = E1.get_scalar_multiplication_hex(private_keys_hex_list[sn_int_my-1], E1.H_hex)
    fee_hex = strToBytes6(hex(10**7))  # / 10**9
    len_hex = strToBytes6(hex(len(random_sn_hex_list)))
    address_fee_len_hex = address_hex + fee_hex.replace("0x", "") + len_hex.replace("0x", "")
    ringSignature_return_list = E1.ringSignature(random_sn_hex_list, sn_hex_my, address_fee_len_hex, kH_hex) 
    
    ringSignature_toStr = E1.ringSignature_toStr(ringSignature_return_list[0], ringSignature_return_list[1], ringSignature_return_list[2], ringSignature_return_list[3], ringSignature_return_list[4])
    print()
    print("Ring Signature Proof: ")
    print(ringSignature_toStr)
    print()
    print("Ring signature verification results: ", E1.ringSignature_verify(ringSignature_toStr))
    print()
    print("withdraw address: ", address_hex)
    print()
    
    sys.exit()
    