/*
 LC3 Rogue
 By: Justin Meiners
 */

#include <stdio.h>
#include <stdlib.h>

#define W 16
#define H 8

unsigned short maze[W * H];
char tileChar[] = " #@KD";
short px, py;
short complete = 0;

void gen_maze()
{
    // fill maze with solid blocks
    for (short i = 0; i < W * H; ++i)
    {
        maze[i] = 1;
    }

    // place player on the left side
    px = 0;
    py = rand() % H;
    short playerIndex = W * py;
    maze[playerIndex] = 2;

    short x = px, y = py;

    while (x < W)
    {
        x += 1;
        maze[x + y * W] = 0;

        y += rand() % 3 - 1;
        y = y % H;
        maze[x + y * W] = 0;
    }

    maze[x - 1 + y * W] = 4;    
}

void print_maze()
{
    for (short i = 0; i < W * H; ++i)
    {
        if (i % W == 0)
        {
            printf("\n");
        }
        unsigned short tileType = maze[i];
        printf("%c", tileChar[tileType]);
    } 
    printf("\n");
}

void move(char input)
{
    short npx = px;
    short npy = py;

    switch (input)
    {
        case 'd':
            npx += 1;
            break;
        case 's':
            npy += 1;
            break;
        case 'a':
            npx -= 1;
            break;
        case 'w':
            npy -= 1;
            break;
    }

    npx = npx % W;
    npy = npy % H;

    unsigned short dest = maze[npx + npy * W];
    if (dest == 0)
    {
        // reset previous
        maze[px + py * W] = 0;
        maze[npx + npy * W] = 2;
        px = npx;
        py = npy;
    }
    else if (dest == 4)
    {
        complete = 1;
    }
}

int main(int argc, const char* argv[])
{
    srand(1245);
    gen_maze();
    while (1) 
    {
        char c = getc(stdin);

        move(c);
        print_maze();

        if (complete)
        {
            printf("Good Job\n");
            gen_maze();
            complete = 0;
        }
    }
}

