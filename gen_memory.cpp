/*
 * This program generates the inputs and also the correct output of the accelerators.
 * It generates two hex files
 * 1. memory.hex => this will contain the initial state of memory and will contain inputs to the accelerators
 * 2. gold.hex => this contains the correct expected state of memory after the accelerators are done processing
 *
 * The program will also print the address and block sizes which should be provided as inputs to the accelerators via CBus.
 * When modifying this file, update the arguments (printed by this program) in src/Testbench.bsv
 */

#include<iostream>
#include<iomanip>
#include<fstream>
#include<math.h>
using namespace std;
#define MLEN 2048

// vector_xor function generates inputs and correct output for vector XOR operation
// Function arguments:
// 1. block_size	number of elements in the vector that are to the XORed
// 2. current_index	current position of index into memory
// 3. input		pointer to the input array
// 4. output		pointer to the output array
// 5. element_length	bitwidth of the each element (8, 16 or 32)
void vector_xor(int block_size, int &current_index, int* input, int* output, int element_length) {
	if (current_index + 2 * ceil((double) (block_size * element_length)/32.0) >= MLEN/2) {
		cout << "Input exceeds half of memory" << endl;
		exit(0);
	}
	int second_index = current_index + ceil((double) (block_size * element_length)/32.0);
	cout << "VX " << element_length << " bit, block size : " << block_size << " (" << current_index << "," << second_index << "," << current_index + MLEN/2 << ")" << endl;

	int k = 32/element_length;
	for (int i = 0; i < block_size;) {
		for (int j = k; (i < block_size) && (j > 0); j--) {
			int val1 = rand() & (((long)1 << element_length) - 1);
			int val2 = rand() & (((long)1 << element_length) - 1);
			int val3 = val1 ^ val2;
			input[current_index] |= (val1 << ((j-1) * element_length));
			input[second_index] |= (val2 << ((j-1) * element_length));
			output[current_index] |= (val1 << ((j-1) * element_length));
			output[second_index] |= (val2 << ((j-1) * element_length));
			output[current_index + MLEN/2] |= (val3 << ((j-1) * element_length));
			i++;
		}
		current_index++;
		second_index++;
	}

	current_index = second_index;
}

// vector_copy function generates inputs and correct output for vector copy operation
// Function arguments:
// 1. block_size	number of elements in the vector that are to the copied
// 2. current_index	current position of index into memory
// 3. input		pointer to the input array
// 4. output		pointer to the output array
// 5. element_length	bitwidth of the each element (8, 16 or 32)
void vector_copy(int block_size, int &current_index, int* input, int* output, int element_length) {
	if (current_index + ceil((double) (block_size * element_length)/32.0) >= MLEN/2) {
		cout << "Input exceeds half of memory" << endl;
		exit(0);
	}
	cout << "VC " << element_length << " bit, block size : " << block_size << " (" << current_index << "," << current_index + MLEN/2 << ")" << endl;

	int k = 32/element_length;
	for (int i = 0; i < block_size;) {
		for (int j = k; (i < block_size) && (j > 0); j--) {
			int val = rand() & (((long)1 << element_length) - 1);
			input[current_index] |= (val << ((j-1) * element_length));
			output[current_index] |= (val << ((j-1) * element_length));
			output[current_index + MLEN/2] |= (val << ((j-1) * element_length));
			i++;
		}
		current_index++;
	}
}

// matrix_transpose function generates inputs and correct output for matrix transpose operation
// Function arguments:
// 1. rows		number of rows in the input matrix
// 2. cols		number of columns in the input matrix
// 3. current_index	current position of index into memory
// 4. input		pointer to the input array
// 5. output		pointer to the output array
// 6. error		when set to true, will create an input that has dimension mismatch error
// 7. half_word		if set to true, bitwidth of elements of matrix is 16, otherwise 32
void matrix_transpose(int rows, int cols, int &current_index, int* input, int* output, bool error, bool half_word) {
	if (((!half_word) && (current_index + rows * cols + 2 >= MLEN/2)) 
			|| ((half_word) && (current_index + ((rows * cols) + 1)/2 + 2 >= MLEN/2))) {
		cout << "Input exceeds half of memory" << endl;
		exit(0);
	}
	if (half_word) {
		cout << "MT 16 bit ";
	} else {
		cout << "MT 32 bit ";
	}
	cout << rows << "x" << cols << " (" << current_index << "," << current_index + MLEN/2 << ")" << endl;

	// The first word contains the dimension of the matrix
	input[current_index] = (rows << 16) | (cols);
	output[current_index] = (rows << 16) | (cols);
	if (!error) {
		input[current_index + MLEN/2] = (cols << 16) | (rows);
		output[current_index + MLEN/2] = (cols << 16) | (rows);
	} else {
		// Introduce a dimension mismatch error
		input[current_index + MLEN/2] = ((cols+1) << 16) | (rows);
		output[current_index + MLEN/2] = ((cols+1) << 16) | (rows);
	}
	current_index++;

	// The second word contains a pointer to the data array
	input[current_index] = current_index + 1;
	output[current_index] = current_index + 1;
	input[current_index + MLEN/2] = current_index + MLEN/2 + 1;
	output[current_index + MLEN/2] = current_index + MLEN/2 + 1;
	current_index++;

	// The actual data follows
	if (half_word) {
		int* input_matrix = (int*) malloc (sizeof(int) * rows*cols);
		int* output_matrix = (int*) malloc (sizeof(int) * rows*cols);
		for (int i = 0; i<(rows*cols)/2; i++) {
			int val1 = rand() & ((1 << 16) - 1);
			int val2 = rand() & ((1 << 16) - 1);
			input_matrix[2*i] = val1;
			input_matrix[2*i + 1] = val2;
		}
		if ((rows*cols)%2 == 1) {
			int val1 = rand() & ((1 << 16) - 1);
			input_matrix[rows*cols - 1] = val1;
		}
		int k = 0;
		for (int j = 0; j<cols; j++) {
			for (int i = 0; i<rows; i++) {
				output_matrix[k++] = input_matrix[i * cols + j];
			}
		}
		for (int i = 0; i<(rows*cols)/2; i++) {
			input[current_index + i] = (input_matrix[2*i] << 16) | (input_matrix[2*i + 1]);
			output[current_index + i] = (input_matrix[2*i] << 16) | (input_matrix[2*i + 1]);
			if (!error) {
				output[current_index + MLEN/2 + i] = (output_matrix[2*i] << 16) | (output_matrix[2*i + 1]);
			}
		}
		if ((rows*cols)%2 == 1) {
			input[current_index + (rows*cols)/2] = (output_matrix[rows*cols - 1] << 16);
			output[current_index + (rows*cols)/2] = (output_matrix[rows*cols - 1] << 16);
			output[current_index + MLEN/2 + (rows*cols)/2] = (output_matrix[rows*cols - 1] << 16);
		}
		current_index += ((rows * cols) + 1) / 2;
	} else {
		for (int i = 0; i<rows; i++) {
			for (int j = 0; j<cols; j++) {
				int val = rand();
				input[current_index + i * cols + j] = val;
				output[current_index + i * cols + j] = val;
				if (!error) {
					output[current_index + MLEN/2 + j * rows + i] = val;
				}
			}
		}
		current_index += rows * cols;
	}
}

int main() {
	// Open the files to write output
	ofstream memfile, goldfile;
	memfile.open("memory.hex", ios::out | ios::trunc);
	goldfile.open("gold.hex", ios::out | ios::trunc);
	if (!memfile.is_open() || !goldfile.is_open()) {
		cout << "Error: Cannot open files for writing" << endl;
		return 0;
	}

	srand(7);

	int input[MLEN] = {0}, output[MLEN] = {0};
	int current_index = 0;

	/*
	 * For vector copy and matrix transpose,
	 * We have used the same function to generate for both integer and floats
	 * because copy and transpose operation will work the same irrespective of
	 * the data type of the elements.
	 */

	// 8 bit Vector XOR
	vector_xor(5, current_index, input, output, 8);

	// 16 bit Vector XOR
	vector_xor(5, current_index, input, output, 16);

	// 32 bit Vector XOR
	vector_xor(5, current_index, input, output, 32);

	// 8 bit Integer Vector copy
	vector_copy(5, current_index, input, output, 8);

	// 16 bit Integer Vector copy
	vector_copy(5, current_index, input, output, 16);

	// 32 bit Integer Vector copy
	vector_copy(5, current_index, input, output, 32);

	// 32 bit Float Vector copy
	vector_copy(5, current_index, input, output, 32);

	// 16 bit Integer Matrix transpose
	matrix_transpose(34, 14, current_index, input, output, false, true);

	// 32 bit Integer Matrix transpose
	matrix_transpose(9, 11, current_index, input, output, false, false);

	// 32 bit Float Matrix transpose
	matrix_transpose(9, 11, current_index, input, output, false, false);

	// Matrix transpose with an error (Dimension mismatch)
	matrix_transpose(1, 2, current_index, input, output, true, false);

	// Print the memory values to the file
	for (int i=0; i < MLEN; i++) {
		memfile << setw(8) << setfill('0') << hex << input[i] << endl;
		goldfile << setw(8) << setfill('0') << hex << output[i] << endl;
	}

	// Close the output files
	memfile.close();
	goldfile.close();
}
