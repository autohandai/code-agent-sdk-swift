#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(void) {
  char line[16384];
  while (fgets(line, sizeof(line), stdin) != NULL) {
    const char *id_key = strstr(line, "\"id\"");
    const char *colon = id_key == NULL ? NULL : strchr(id_key, ':');
    long id = colon == NULL ? 0 : strtol(colon + 1, NULL, 10);

    if (strstr(line, "autohand.mcp.listServers") != NULL) {
      printf(
          "{\"jsonrpc\":\"2.0\",\"id\":%ld,\"result\":{\"servers\":[{\"name\":\"fixture\",\"status\":\"connected\",\"toolCount\":1}]}}\n",
          id);
    } else {
      printf("{\"jsonrpc\":\"2.0\",\"id\":%ld,\"result\":{\"success\":true}}\n", id);
    }
    fflush(stdout);
  }
  return 0;
}
