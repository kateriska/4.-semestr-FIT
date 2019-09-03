/*
  Autor - Katerina Fortova (xforto00)
  Projekt - IOS - 2. projekt (River crossing problem)
  Datum - duben 2019
  Vyvoj, testovani - GNU Ubuntu, merlin
*/

#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<stdbool.h>
#include<unistd.h>
#include<semaphore.h>
#include<sys/wait.h>
#include<sys/types.h>
#include<sys/shm.h>
#include<fcntl.h>
#include<time.h>
#include<errno.h>

#define SEMAPHORE1_NAME "/semaphore_xforto00_synchronization_a"
#define SEMAPHORE2_NAME "/semaphore_xforto00_synchronization_b"
#define SEMAPHORE3_NAME "/semaphore_xforto00_synchronization_c"
#define SEMAPHORE4_NAME "/semaphore_xforto00_synchronization_d"
#define SEMAPHORE5_NAME "/semaphore_xforto00_synchronization_e"

#define LOCKED 0
#define UNLOCKED 1


// semafory:
sem_t *writing_to_file = NULL; // pristup a inkrementace sdilenych promennych
sem_t *captain_sleeping = NULL; // semafor pro pripad kdy kapitan zahaji plavbu zacatkem spanku
sem_t *ship_leaves = NULL; // semafor pro uzamknuti lodky co pluje pryc
sem_t *hacker_creates_group = NULL; // kapitan hacker tvori skupinku na lod
sem_t *serf_creates_group = NULL; // kapitan serf tvori skupinku na lod

// sdilene promenne - id:
int hackers_count_id = 0;
int serfs_count_id = 0;
int counter_id = 0; // zapisovani do sdileneho souboru - poradova cisla akci
// kapacita mola - lide na molu:
int people_on_pier_id = 0;
// aktualni pocet hackers a serfs na molu:
int hackers_on_pier_id = 0;
int serfs_on_pier_id = 0;
// zjisteni posledniho indexu hackera i serfa i pro druhy proces
int this_hacker_index_id = 0;
int this_serf_index_id = 0;

// sdilene promenne:
int *hackers_count = NULL;
int *serfs_count = NULL;
int *counter = NULL;
int *people_on_pier = NULL;
int *hackers_on_pier = NULL;
int *serfs_on_pier = NULL;
int *this_hacker_index = NULL;
int *this_serf_index = NULL;

FILE *out; // proj2.out - zapis dat


typedef struct Parametres
{
  long hackers_serfs_count; // P - pocet generovanych osob v kazde kategorii - bude vytvoreno P hackers a P serfs
  long hackers_max_count; // H - max. doba po kterou bude generovan novy proces hackers
  long serfs_max_count; // S - max. doba po kterou bude generovan novy proces serfs
  long sail_max_time; // R - max. cas plavby
  long return_pier_max_time; // W - max. doba po ktere se osoba vraci zpet na molo (pokud bylo pred tim plne)
  long pier_capacity; // C - kapacita mola

} parametre;

// kontrola argumentu:

int checkArguments(int arg_count, char *arg[], parametre *Parametres)
{
  char *argument_ending;

  if (arg_count != 7)
  {
    fprintf(stderr, "Chyba - Spatny pocet argumentu!\n");
    return EXIT_FAILURE;
  }

  Parametres->hackers_serfs_count = strtol(arg[1], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || ( Parametres->hackers_serfs_count < 2 || (Parametres->hackers_serfs_count % 2) != 0 ))
  {
    fprintf(stderr, "Chyba - Argument P (pocet gen. osob v kazde kategorii) zadavejte v rozsahu P >= 2 && P je delitelne 2!\n");
    return EXIT_FAILURE;
  }

  Parametres->hackers_max_count = strtol(arg[2], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || ( Parametres->hackers_max_count < 0 || Parametres->hackers_max_count >2000 ))
  {
    fprintf(stderr, "Chyba - Argument H (max. doba generovani 1 hackera) zadavejte v rozsahu H >= 0 && H<=2000!\n");
    return EXIT_FAILURE;
  }

  Parametres->serfs_max_count = strtol(arg[3], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || ( Parametres->serfs_max_count < 0 || Parametres->serfs_max_count >2000 ))
  {
    fprintf(stderr, "Chyba - Argument S (max. doba generovani 1 serfa) zadavejte v rozsahu S >= 0 && S<=2000!\n");
    return EXIT_FAILURE;
  }

  Parametres->sail_max_time = strtol(arg[4], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || ( Parametres->sail_max_time < 0 || Parametres->sail_max_time >2000 ))
  {
    fprintf(stderr, "Chyba - Argument R (max. doba plavby) zadavejte v rozsahu R >= 0 && R<=2000!\n");
    return EXIT_FAILURE;
  }

  Parametres->return_pier_max_time = strtol(arg[5], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || ( Parametres->return_pier_max_time < 20 || Parametres->return_pier_max_time >2000 ))
  {
    fprintf(stderr, "Chyba - Argument W (max.doba vraceni na molo) zadavejte v rozsahu W >= 20 && W<=2000!\n");
    return EXIT_FAILURE;
  }

  Parametres->pier_capacity = strtol(arg[6], &argument_ending, 10);
  if (*argument_ending != '\0' || errno == ERANGE || Parametres->pier_capacity < 5)
  {
    fprintf(stderr, "Chyba - Argument C (kapacita mola) zadavejte v rozsahu C >= 5!\n");
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}

// inicializace semaforu a sdilene pameti:
bool inicialize()
{
  if ((hackers_count_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((hackers_count = shmat(hackers_count_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((serfs_count_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((serfs_count = shmat(serfs_count_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((counter_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((counter = shmat(counter_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((people_on_pier_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((people_on_pier = shmat(people_on_pier_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((hackers_on_pier_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((hackers_on_pier = shmat(hackers_on_pier_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((serfs_on_pier_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((serfs_on_pier = shmat(serfs_on_pier_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((this_hacker_index_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((this_hacker_index = shmat(this_hacker_index_id, NULL, 0)) == NULL)
  {
    return false;
  }
  if ((this_serf_index_id = shmget(IPC_PRIVATE, sizeof(int), IPC_CREAT | 0666)) == -1)
  {
    return false;
  }
  if ((this_serf_index = shmat(this_serf_index_id, NULL, 0)) == NULL)
  {
    return false;
  }

  if ((writing_to_file = sem_open(SEMAPHORE1_NAME, O_CREAT | O_EXCL, 0666, UNLOCKED)) == SEM_FAILED)
  {
    return false;
  }
  if ((captain_sleeping = sem_open(SEMAPHORE2_NAME, O_CREAT | O_EXCL, 0666, UNLOCKED)) == SEM_FAILED)
  {
    return false;
  }
  if ((ship_leaves = sem_open(SEMAPHORE3_NAME, O_CREAT | O_EXCL, 0666, UNLOCKED)) == SEM_FAILED)
  {
    return false;
  }
  if ((hacker_creates_group = sem_open(SEMAPHORE4_NAME, O_CREAT | O_EXCL, 0666, UNLOCKED)) == SEM_FAILED)
  {
    return false;
  }
  if ((serf_creates_group = sem_open(SEMAPHORE5_NAME, O_CREAT | O_EXCL, 0666, UNLOCKED)) == SEM_FAILED)
  {
    return false;
  }

  return true;
}

// uklid sdilene pameti, semaforu, kontrola uzavreni souboru .out
int cleaning()
{

  if (fclose(out) == EOF)
  {
    fprintf(stderr, "Chyba - Soubor se nepodarilo zavrit\n");
    return EXIT_FAILURE;
  }

  sem_close(writing_to_file);
  sem_unlink(SEMAPHORE1_NAME);
  sem_close(captain_sleeping);
  sem_unlink(SEMAPHORE2_NAME);
  sem_close(ship_leaves);
  sem_unlink(SEMAPHORE3_NAME);
  sem_close(hacker_creates_group);
  sem_unlink(SEMAPHORE4_NAME);
  sem_close(serf_creates_group);
  sem_unlink(SEMAPHORE5_NAME);

  free(hackers_count);
  shmctl(hackers_count_id, IPC_RMID, NULL);
  free(serfs_count);
  shmctl(serfs_count_id, IPC_RMID, NULL);
  free(counter);
  shmctl(counter_id, IPC_RMID, NULL);
  free(people_on_pier);
  shmctl(people_on_pier_id, IPC_RMID, NULL);
  free(hackers_on_pier);
  shmctl(hackers_on_pier_id, IPC_RMID, NULL);
  free(serfs_on_pier);
  shmctl(serfs_on_pier_id, IPC_RMID, NULL);
  free(this_hacker_index);
  shmctl(this_hacker_index_id, IPC_RMID, NULL);
  free(this_serf_index);
  shmctl(this_serf_index_id, IPC_RMID, NULL);

  return EXIT_SUCCESS;
}

// proces pro hackera:
void hacker(int index_hacker, parametre Parametres)
{
  bool captain = false; // inicializace kapitana
  bool leave_and_come_back = false; // proces, ktery musi odejit a zpet se vratit
  bool mixed_sail = false; // mix plavba - hackers a surfs - 2+2

  sem_wait(writing_to_file);
  (*this_hacker_index)++; // zjisteni indexu i pro druhy proces
  sem_post(writing_to_file);


  // prichod na molo:

  sem_wait(writing_to_file);
  fprintf(out, "%d\t: HACK %d\t: starts\n", ++(*counter), index_hacker);
  sem_post(writing_to_file);

  sem_wait(writing_to_file);
  (*people_on_pier)++; // inkrementace - dalsi clovek na molu
  sem_post(writing_to_file);



  if (*people_on_pier > Parametres.pier_capacity) // na molo se nevejde
  {
    leave_and_come_back = true;
    sem_wait(writing_to_file);
    (*people_on_pier)--;
    sem_post(writing_to_file);

    sem_wait(writing_to_file);
    fprintf(out, "%d\t: HACK %d\t: leaves queue\t: %d\t: %d\n", ++(*counter), index_hacker, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }
  else
  {
    leave_and_come_back = false;
    sem_wait(writing_to_file);
    (*hackers_on_pier)++; // inkrementace - dalsi hacker na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: HACK %d\t: waits\t: %d\t: %d\n", ++(*counter), index_hacker, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }


  if (leave_and_come_back == true)
  {
    sem_wait(writing_to_file);
    (*people_on_pier)++;
    sem_post(writing_to_file);

    while (*people_on_pier <= Parametres.pier_capacity) // vic lidi na molu jak kapacita, hacker musi odejit na chvili
    {
    // proces se musi na nahodnou dobu uspat
      usleep((rand() % Parametres.return_pier_max_time) * 1000);
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: is back\n", ++(*counter), index_hacker); // hacker se pokousi dostat zpet na molo
      sem_post(writing_to_file);
    }
  }
  // po dobre kapacite se vrati zpet na molo, ceka
  if (leave_and_come_back == true)
  {
    sem_wait(writing_to_file);
    (*hackers_on_pier)++;
    sem_post(writing_to_file);

    sem_wait(writing_to_file);
    fprintf(out, "%d\t: HACK %d\t: waits\t: %d\t: %d\n", ++(*counter), index_hacker, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }

  // tvoreni skupinky - semafor na zamceni
  sem_wait(hacker_creates_group);
  // tvoreni skupin - povoleni vhodnych skupin - 4 hackers, 4 serfs, 2+2 h a s
  if ( ((*hackers_on_pier) >=4) || ((*hackers_on_pier >=2) && (*serfs_on_pier >= 2)))
  {
    captain = true; // tenhle hacker se stava kapitanem a zahaji se plavba
  }

  if ((*hackers_on_pier)>=4)
  {
    mixed_sail = false;
  }
  else if (((*hackers_on_pier >=2) && (*serfs_on_pier >= 2)))
  {
    mixed_sail = true;
  }
  sem_post(hacker_creates_group);

  if (captain == true)
  {
    // kapitan uzamyka lodku
    sem_wait(ship_leaves);

    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);


    if (mixed_sail == true) // plavba 2+2
    {
      sem_wait(writing_to_file);
      (*hackers_on_pier)--;
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // snizeni poctu hackers na molu
      sem_post(writing_to_file);

      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // snizeni poctu serfs na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*serfs_on_pier)--;
      sem_post(writing_to_file);
    }
    else
    {
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // plavba jen s 4 hackers - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // plavba jen s 4 hackers - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // plavba jen s 4 hackers - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // plavba jen s 4 hackers - snizeni o ctyri na molu
      sem_post(writing_to_file);
    }

    // kapitan tiskne zacatek plavby
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: HACK %d\t: boards\t: %d\t: %d\n", ++(*counter), index_hacker, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);

    // kapitan spi - zamknout semafor a nikoho nepustit
    sem_wait(captain_sleeping);
    usleep((rand() % Parametres.sail_max_time) * 1000); // kapitan spi - simulace plavby
    sem_post(captain_sleeping); // kapitan odemkne semafor po spani - konec plavby

    // odchod cestujicich z lodky - kapitana zatim ne
    if (mixed_sail == false) // 4 hackers na lodi
    {
      // musim zjistit indexy tech trech cestujicich pred tim co nastoupili (index kapitana -1 ...- 3)
      int h_first_member_hackers = index_hacker - 3;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), h_first_member_hackers, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      int h_second_member_hackers = index_hacker - 2;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), h_second_member_hackers, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      int h_third_member_hackers = index_hacker - 1;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), h_third_member_hackers, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);
    }
    else // 2+2
    {
      int h_first_member_mix = index_hacker - 1;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), h_first_member_mix, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), (*this_serf_index), (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), --(*this_serf_index), (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

    }
    // kapitan konecne vystupuje jako posledni
    // kapitan tisne odchod:
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: HACK %d\t: captain exits\t: %d\t: %d\n", ++(*counter), index_hacker, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);

    // kapitan lodku znovu odemyka pro dalsi plavbu
    sem_post(ship_leaves);
  }
    captain = false;
    exit(EXIT_SUCCESS);

}

// proces pro serfa:
void serf(int index_serf, parametre Parametres)
{
  bool captain = false; // inicializace kapitana
  bool leave_and_come_back = false; // proces, ktery musi odejit a zpet se vratit
  bool mixed_sail = false; // mix plavba - hackers a surfs - 2+2
  // zjisteni indexu hackera a serf i pro druhy proces
  sem_wait(writing_to_file);
  (*this_serf_index)++;
  sem_post(writing_to_file);

//  int capacity_of_ship = 4; // kapacita lodky
  // prichod na molo:
  sem_wait(writing_to_file);
  fprintf(out, "%d\t: SERF %d\t: starts\n", ++(*counter), index_serf);
  sem_post(writing_to_file);

  sem_wait(writing_to_file);
  (*people_on_pier)++; // inkrementace - dalsi clovek na molu
  sem_post(writing_to_file);



  if (*people_on_pier > Parametres.pier_capacity) // na molo se nevejde
  {
    leave_and_come_back = true;
    sem_wait(writing_to_file);
    (*people_on_pier)--;
    sem_post(writing_to_file);

    sem_wait(writing_to_file);
    fprintf(out, "%d\t: SERF %d\t: leaves queue\t: %d\t: %d\n", ++(*counter), index_serf, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }
  else
  {
    leave_and_come_back = false;
    sem_wait(writing_to_file);
    (*serfs_on_pier)++; // inkrementace - dalsi serf na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: SERF %d\t: waits\t: %d\t: %d\n", ++(*counter), index_serf, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }

  if (leave_and_come_back == true)
  {
    sem_wait(writing_to_file);
    (*people_on_pier)++;
    sem_post(writing_to_file);
    while (*people_on_pier <= Parametres.pier_capacity) // vic lidi na molu jak kapacita, serf musi odejit na chvili
    {
      // proces se musi na nahodnou dobu uspat
      usleep((rand() % Parametres.return_pier_max_time) * 1000);
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: is back\n", ++(*counter), index_serf); // serf se pokousi dostat zpet na molo
      sem_post(writing_to_file);
    }
  }
  // po dobre kapacite se vrati zpet na molo, ceka
  if (leave_and_come_back == true)
  {
    sem_wait(writing_to_file);
    (*serfs_on_pier)++;
    sem_post(writing_to_file);

    sem_wait(writing_to_file);
    fprintf(out, "%d\t: SERF %d\t: waits\t: %d\t: %d\n", ++(*counter), index_serf, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);
  }
  sem_wait(serf_creates_group);
  // tvoreni skupin - povoleni vhodnych skupin - 4 hackers, 4 serfs, 2+2 h a s
  if ( ((*serfs_on_pier) >=4) || ((*serfs_on_pier >=2) && (*hackers_on_pier >= 2)))
  {
    captain = true; // tenhle serf se stava kapitanem a zahaji se plavba
  }

  if ((*serfs_on_pier)>=4)
  {
    mixed_sail = false;
  }
  else if (((*serfs_on_pier >=2) && (*hackers_on_pier >= 2)))
  {
    mixed_sail = true;
  }
  sem_post(serf_creates_group);
  if (captain == true)
  {
    // kapitan uzamyka lodku
    sem_wait(ship_leaves);

    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);
    sem_wait(writing_to_file);
    (*people_on_pier)--; // clovek je na lodi, snizeni poctu lidi na molu
    sem_post(writing_to_file);


    if (mixed_sail == true) // plavba 2+2
    {
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // snizeni poctu serfs na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // snizeni poctu serfs na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // snizeni poctu hackers na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*hackers_on_pier)--; // snizeni poctu hackers na molu
      sem_post(writing_to_file);
    }
    else
    {
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // plavba jen s 4 serfs - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // plavba jen s 4 serfs - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // plavba jen s 4 serfs - snizeni o ctyri na molu
      sem_post(writing_to_file);
      sem_wait(writing_to_file);
      (*serfs_on_pier)--; // plavba jen s 4 serfs - snizeni o ctyri na molu
      sem_post(writing_to_file);
    }

    // kapitan tiskne zacatek plavby
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: SERF %d\t: boards\t: %d\t: %d\n", ++(*counter), index_serf, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);

    // kapitan spi - zamknout semafor a nikoho nepustit
    sem_wait(captain_sleeping);
    usleep((rand() % Parametres.sail_max_time) * 1000); // kapitan spi - simulace plavby
    sem_post(captain_sleeping); // kapitan odemkne semafor po spani - konec plavby

    // odchod cestujicich z lodky - kapitana zatim ne
    if (mixed_sail == false) // 4 serfs na lodi
    {
      // musim zjistit indexy tech trech cestujicich pred tim co nastoupili (index kapitana -1 ...- 3)
      int s_first_member_serfs = index_serf - 3;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), s_first_member_serfs, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      int s_second_member_serfs = index_serf - 2;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), s_second_member_serfs, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      int s_third_member_serfs = index_serf - 1;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), s_third_member_serfs, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);
    }
    else // 2+2
    {

      int s_first_member_mix = index_serf - 1;
      sem_wait(writing_to_file);
      fprintf(out, "%d\t: SERF %d\t: member exits\t: %d\t: %d\n", ++(*counter), s_first_member_mix, (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), (*this_hacker_index), (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);

      sem_wait(writing_to_file);
      fprintf(out, "%d\t: HACK %d\t: member exits\t: %d\t: %d\n", ++(*counter), --(*this_hacker_index), (*hackers_on_pier), (*serfs_on_pier));
      sem_post(writing_to_file);



    }
    // kapitan konecne vystupuje jako posledni
    // kapitan tisne odchod:
    sem_wait(writing_to_file);
    fprintf(out, "%d\t: SERF %d\t: captain exits\t: %d\t: %d\n", ++(*counter), index_serf, (*hackers_on_pier), (*serfs_on_pier));
    sem_post(writing_to_file);

    // kapitan lodku znovu odemyka pro dalsi plavbu
    sem_post(ship_leaves);
  }
    captain = false;
    exit(EXIT_SUCCESS);
}

int main(int argc, char *argv[])
{
  parametre Parametres;

  if (checkArguments(argc, argv, &Parametres) == EXIT_FAILURE)
  {
    fprintf(stderr, "Chyba - Argumenty jsou zadane spatne!\n");
    return EXIT_FAILURE;
  }
  // uklid pred behem programu
  sem_close(writing_to_file);
  sem_unlink(SEMAPHORE1_NAME);
  sem_close(captain_sleeping);
  sem_unlink(SEMAPHORE2_NAME);
  sem_close(ship_leaves);
  sem_unlink(SEMAPHORE3_NAME);
  sem_close(hacker_creates_group);
  sem_unlink(SEMAPHORE4_NAME);
  sem_close(serf_creates_group);
  sem_unlink(SEMAPHORE5_NAME);

  free(hackers_count);
  shmctl(hackers_count_id, IPC_RMID, NULL);
  free(serfs_count);
  shmctl(serfs_count_id, IPC_RMID, NULL);
  free(counter);
  shmctl(counter_id, IPC_RMID, NULL);
  free(people_on_pier);
  shmctl(people_on_pier_id, IPC_RMID, NULL);
  free(hackers_on_pier);
  shmctl(hackers_on_pier_id, IPC_RMID, NULL);
  free(serfs_on_pier);
  shmctl(serfs_on_pier_id, IPC_RMID, NULL);
  free(this_hacker_index);
  shmctl(this_hacker_index_id, IPC_RMID, NULL);
  free(this_serf_index);
  shmctl(this_serf_index_id, IPC_RMID, NULL);



  if (inicialize() == false)
  {
    fprintf(stderr, "Chyba - Inicializace sdilenych promennych a semaforu se nezdarila!\n");
    return EXIT_FAILURE;
  }

  out = fopen("proj2.out", "w"); // vytvoreni a otevreni zapisoveho souboru

  if (out == NULL)
  {
    fprintf(stderr, "Chyba - Soubor pro zapis dat proj2.out se nepodarilo otevrit!\n");
    return EXIT_FAILURE;
  }

  setbuf(out,NULL); // zacatek zapisovani do souboru
  srand(time(NULL)); // funkce rand()


  pid_t hackers_process; // proces pro praci s hackers
  pid_t serfs_process; // proces pro praci s serfs
  pid_t main_process = fork();

  if (main_process == 0) // child process
  {
    // generovani processu serfs
    for (int i = 0; i < Parametres.hackers_serfs_count; i++) // generovani P serfs
    {
      serfs_process = fork();

      if (serfs_process == 0) // proces serf - generovani dalsiho serfa
      {
        serf((i + 1), Parametres);
      }
      else if (serfs_process > 0) // prodleva mezi dalsim generovanim noveho sefra
      {
        if (Parametres.serfs_max_count == 0) // generovani noveho procesu ihned
        {
          continue;
        }
        else // prodleva na nahodnou dobu
        {
          usleep((rand() % Parametres.serfs_max_count) * 1000);
        }
      }
      else
      {
        fprintf(stderr, "Chyba - Fork() se nezdarilo!\n");
        if (cleaning() == EXIT_FAILURE)
        {
          fprintf(stderr, "Chyba - Clean() se nezdarilo!\n");
          return EXIT_FAILURE;
        }
        return EXIT_FAILURE;
      }
    }

    // cekani na ukonceni vsech serfa
    for (int i = 0; i < Parametres.hackers_serfs_count; i++)
    {
      waitpid(-1, NULL, 0);
    }

    exit (EXIT_SUCCESS);
  }
  else if (main_process > 0) // parent process - generovani procesu hacker
  {
    // generovani processu hacker
    for (int i = 0; i < Parametres.hackers_serfs_count; i++) // generovani P hackers
    {
      hackers_process = fork();

      if (hackers_process == 0) // proces hacker - generovani dalsiho hackera
      {
        hacker((i + 1), Parametres);
      }
      else if (hackers_process > 0) // prodleva mezi dalsim generovanim noveho hackera
      {
        if (Parametres.hackers_max_count == 0) // generovani noveho procesu ihned
        {
          continue;
        }
        else // prodleva na nahodnou dobu
        {
          usleep((rand() % Parametres.hackers_max_count) * 1000);
        }
      }
      else
      {
        fprintf(stderr, "Chyba - Fork() se nezdarilo!\n");
        if (cleaning() == EXIT_FAILURE)
        {
          fprintf(stderr, "Chyba - Clean() se nezdarilo!\n");
          return EXIT_FAILURE;
        }
        return EXIT_FAILURE;
      }
    }

    // cekani na ukonceni vsech hackers
    for (int i = 0; i < Parametres.hackers_serfs_count; i++)
    {
      waitpid(-1, NULL, 0);
    }

    exit (EXIT_SUCCESS);
  }
  else
  {
    fprintf(stderr, "Chyba - Fork() se nezdarilo!\n");
    if (cleaning() == EXIT_FAILURE)
    {
      fprintf(stderr, "Chyba - Clean() se nezdarilo!\n");
      return EXIT_FAILURE;
    }
    return EXIT_FAILURE;
  }

  waitpid(-1, NULL,0);
  if (cleaning() == EXIT_FAILURE)
  {
    fprintf(stderr, "Chyba - Clean() se nezdarilo!\n");
    return EXIT_FAILURE;
  }

  return EXIT_SUCCESS;
}
