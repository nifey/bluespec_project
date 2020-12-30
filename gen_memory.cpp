#include<iostream>
#include<iomanip>
#include<fstream>
using namespace std;
#define MLEN 1024

void matrix_transpose(int rows, int cols, int &current_index, int* input, int* output, bool error) {
	if (current_index + rows * cols + 2 >= MLEN/2) {
		cout << "Input exceeds half of memory" << endl;
		exit(0);
	}
	cout << "MT 32 bit " << rows << "x" << cols << " (" << current_index << "," << current_index + MLEN/2 << ")" << endl;

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

	// 32 bit Matrix transpose of 8x8
	matrix_transpose(4, 4, current_index, input, output, true);
	matrix_transpose(4, 4, current_index, input, output, false);

	// Print the memory values to the file
	for (int i=0; i < MLEN; i++) {
		memfile << setw(8) << setfill('0') << hex << input[i] << endl;
		goldfile << setw(8) << setfill('0') << hex << output[i] << endl;
	}

	// Close the output files
	memfile.close();
	goldfile.close();
}
