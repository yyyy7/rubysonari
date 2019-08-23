import java.util.*;
class Main {
  public static void main(String[ ] args) {
      Set<String> set = new HashSet<>();
      set.add("aaaaaa ");
      set.add("bbbbbb ");
      List<String> s = set.stream().map(String::trim).collect(Collectors.toList());
      System.out.println(s);
      System.out.println(set);
  }
}