#include <pthread.h>
#include <semaphore.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <unistd.h>

#define ALLOC_SLEEP_TIME 10
#define FREE_SLEEP_TIME 15

sem_t created;
void* v[10];

char* timestr(char* buf, size_t bufsiz)
{
    struct timespec ts;
    clock_gettime(CLOCK_REALTIME, &ts);
    snprintf(buf, bufsiz, "%d.%03lu", (int)ts.tv_sec, (long)ts.tv_nsec / 1000000);
}

static void* delete_stuff(void* arg)
{
    (void) arg;
    int i = 0;
    char timebuf[20];
    for(i=0; i < 10; ++i) {
        sleep(FREE_SLEEP_TIME);
        sem_wait(&created);
        timestr(timebuf, 20);
        printf("%s,freeing %d\n", timebuf, i);
        free(v[i]);
    }
    return NULL;
}

void* allocate_memory()
{
    int i=0;
    void* mem = malloc(1*1024*1024);
    for(i=0; i<32; ++i)
    {
        mem = realloc(mem, i*1024*1024);
        usleep(100000);
    }
    return mem;
}

int main(int argc, char **argv)
{
    int i, error;
    char timebuf[20];
    pthread_t deleter;
    if ((error = pthread_create(&deleter, NULL, delete_stuff, NULL)) < 0) {
        perror("pthread_create");
        return EXIT_FAILURE;
    }
    sem_init(&created, 0, 0);
    for (i=0; i <10; ++i) {
        timestr(timebuf, 20);
        printf("%s,mallocing %d\n", timebuf, i);
        v[i] = allocate_memory();
        sem_post(&created);
        sleep(ALLOC_SLEEP_TIME);
    }
    if ((error = pthread_join(deleter, NULL)) < 0) {
        perror("pthread_join");
        return EXIT_FAILURE;
    }
    return 0;
}
