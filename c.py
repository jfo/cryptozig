import unittest
import codecs
from collections import Counter
from word_scorer.WordScorer import WordScorer

class Challenge6Methods(unittest.TestCase):

    def test_hamming_distance(self):
        self.assertEqual(hamming_distance(b'this is a test', b'wokka wokka!!!'), 37)


def hamming_distance(bytes_string1, bytes_string2):
    return sum([bin(a ^ b).count('1') for a, b in zip(bytes_string1, bytes_string2)])


def open_datafile(file_name):
    data = open(file_name, 'rb').read()       # Needs 'b' mode so data is a byte object and not a string
    return codecs.decode(data, 'base64')


def generate_hamming_distance_array(raw_data, max_keysize):

    result_array = []

    for keysize in range(2, max_keysize):
        partitioned_data = [raw_data[i:i + keysize] for i in range(0, len(raw_data), keysize)]

        # NB: The ' - 1' bit below is to avoid running off the end of the array
        hamming_distance_array = [hamming_distance(partitioned_data[j], partitioned_data[j + 1])
                                  for j in range(0, len(partitioned_data) - 1, 2)]

        # print(sum(hamming_distance_array))
        result_array += [(keysize, sum(hamming_distance_array))]

    return result_array


def get_smallest_keysizes(array, number_to_return):

    # Sort
    sorted_array = sorted(array, key=lambda keysize_tuple: keysize_tuple[1])
    # Return slice
    return [ sorted_array[key][0] for key in range(number_to_return) ]


def generate_block_of_slice(raw_data, keysize):

    result_array = []
    for i in range(keysize):
        partitioned_data = [raw_data[i+j] for j in range(0, len(raw_data) - keysize, keysize)]

        # print(partitioned_data)
        result_array += [partitioned_data]

    return result_array


def single_char_xor(letter, array):
    return [i ^ letter for i in array]


def repeating_key_xor(key, input):
    return ''.join([chr(i[1] ^ key[i[0] % len(key)]) for i in enumerate(input)])


raw_data = open_datafile('6.txt')
keysize_hamming_array = generate_hamming_distance_array(raw_data, 40)

# Get smallest n keysizes - I picked 3 for fun
candidate_keysizes = get_smallest_keysizes(keysize_hamming_array, 3)
print("[+] Candidate key sizes are: " + candidate_keysizes.__str__())

scorer = WordScorer()

for keysize in candidate_keysizes:
    slice_array = generate_block_of_slice(raw_data, keysize)

    guessed_key = ''
    for slice in slice_array:

        best_frequency_score = 0
        for letter in range(255):
            result = single_char_xor(letter, slice)
            string_result = Counter([chr(i) for i in result])
            # print(string_result)
            frequency_score = scorer.compare_histogram(string_result)
            if best_frequency_score < frequency_score:
                best_frequency_score = frequency_score
                best_key_letter = letter

        # print("Best match score is " + str(best_frequency_score))
        # print("Best match letter is " + chr(best_key_letter))
        guessed_key += chr(best_key_letter)

    print("[+] Best guess key for keysize {} is: {}".format(str(keysize), guessed_key))


# Could do:
# Pass each best guess key set through wordscorer to pick best one
# Rational for not doing it: No one said the key has to be words

# So manually take the first key only
key = b'Terminator X: Bring the noise'
print("[+] Using key: " + key.decode())
result = repeating_key_xor(key, raw_data)
print("[+] Decoded text is:")
print(result)


    # print(keysize_hamming_array)
#if __name__ == '__main__':
#    unittest.main()
