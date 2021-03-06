// coef2mif.cpp : Defines the entry point for the console application.
//

#include "stdafx.h"
#include <iostream>
#include <fstream>
#include <sstream>
#include <string>
#include <iomanip>

using namespace std;

int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		cout << "Need file coef arguments\n";
		return -1;
	}
	cout << "WIDTH = 16;\n";
	cout << "DEPTH = 512;\n";
	cout << "ADDRESS_RADIX = HEX;\n";
	cout << "DATA_RADIX = HEX;\n";
	cout << "CONTENT BEGIN\n";

		ifstream infile(argv[1]);
		string line;
		unsigned int i = 0;
		try
		{
			while (getline(infile, line))
			{
				short k = std::stoi(line);
				cout << std::setw(4) << std::setfill('0') << std::hex;
				cout << i << " : ";
				cout << std::setw(4) << std::setfill('0') << std::hex;
				cout << k;
				cout << ";\n";
				i++;
			}
		}
		catch (...) {};
		while (i < 512)
		{
			cout << std::setw(4) << std::setfill('0') << std::hex;
			cout << i << " : 0000;\n";
			i++;
		}

	cout << "END\n";
	return 0;
}

